#!/usr/bin/env node
/**
 * Main ingestion pipeline for the AlfaNutrition RAG system.
 *
 * Reads markdown knowledge documents, chunks them, generates embeddings,
 * and upserts to Pinecone.
 *
 * Usage:
 *   npm run ingest                           # Full ingestion
 *   npm run ingest -- --dry-run              # Preview without uploading
 *   npm run ingest -- --file 01_exercise_science.md  # Process single file
 *   npm run ingest -- --use-llm-chunking     # Enable LLM coherence pass
 *   npm run ingest -- --window-size 256      # Custom window size
 *   npm run ingest -- --overlap 64           # Custom overlap
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { glob } from "glob";
import chalk from "chalk";
import OpenAI from "openai";

import { chunkDocument, type ChunkerConfig } from "./chunker.js";
import { embedChunks, formatEmbeddingStats, getEmbeddingDimensions, type EmbedderConfig } from "./embedder.js";
import { PineconeStore } from "./pinecone-store.js";
import { countTokens, formatCost, estimateEmbeddingCost, printProgress } from "./utils.js";

// ---------------------------------------------------------------------------
// Load environment
// ---------------------------------------------------------------------------

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "..", "..");
const RAG_DIR = path.resolve(__dirname, "..");
const KNOWLEDGE_DIR = path.join(RAG_DIR, "knowledge");

// Load .env from the project root.
import dotenv from "dotenv";
dotenv.config({ path: path.join(ROOT_DIR, ".env") });

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

interface CliArgs {
  dryRun: boolean;
  file?: string;
  useLlmChunking: boolean;
  windowSize: number;
  overlap: number;
  minChunkTokens: number;
  model: string;
  dimensions?: number;
}

function parseArgs(): CliArgs {
  const args = process.argv.slice(2);
  const result: CliArgs = {
    dryRun: false,
    useLlmChunking: false,
    windowSize: 512,
    overlap: 128,
    minChunkTokens: 100,
    model: process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small",
    dimensions: process.env.OPENAI_EMBEDDING_DIMENSIONS
      ? parseInt(process.env.OPENAI_EMBEDDING_DIMENSIONS, 10)
      : undefined,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--dry-run":
        result.dryRun = true;
        break;
      case "--file":
        result.file = args[++i];
        break;
      case "--use-llm-chunking":
        result.useLlmChunking = true;
        break;
      case "--window-size":
        result.windowSize = parseInt(args[++i], 10);
        break;
      case "--overlap":
        result.overlap = parseInt(args[++i], 10);
        break;
      case "--min-chunk-tokens":
        result.minChunkTokens = parseInt(args[++i], 10);
        break;
      case "--model":
        result.model = args[++i];
        break;
      case "--dimensions":
        result.dimensions = parseInt(args[++i], 10);
        break;
      case "--help":
      case "-h":
        printUsage();
        process.exit(0);
    }
  }

  return result;
}

function printUsage(): void {
  console.log(`
${chalk.bold("AlfaNutrition RAG Ingestion Pipeline")}

${chalk.yellow("Usage:")}
  npm run ingest [options]

${chalk.yellow("Options:")}
  --dry-run              Preview chunks without embedding or uploading
  --file <name>          Process a single file (e.g. 01_exercise_science.md)
  --use-llm-chunking     Enable LLM-based coherence scoring (costs extra)
  --window-size <n>      Token window size (default: 512)
  --overlap <n>          Token overlap between chunks (default: 128)
  --min-chunk-tokens <n> Minimum chunk size in tokens (default: 100)
  --model <name>         Embedding model (default: text-embedding-3-small)
  --dimensions <n>       Override embedding dimensions
  --help, -h             Show this help message
`);
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

function validateEnv(dryRun: boolean): void {
  if (!process.env.OPENAI_API_KEY) {
    console.error(chalk.red("Error: OPENAI_API_KEY is not set in .env"));
    process.exit(1);
  }
  if (!dryRun) {
    if (!process.env.PINECONE_API_KEY) {
      console.error(chalk.red("Error: PINECONE_API_KEY is not set in .env"));
      process.exit(1);
    }
    if (!process.env.PINECONE_INDEX_NAME) {
      console.error(chalk.red("Error: PINECONE_INDEX_NAME is not set in .env"));
      process.exit(1);
    }
  }
}

// ---------------------------------------------------------------------------
// Main pipeline
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const args = parseArgs();
  validateEnv(args.dryRun);

  console.log(chalk.bold.blue("\n  AlfaNutrition RAG Ingestion Pipeline\n"));
  console.log(chalk.gray(`  Mode: ${args.dryRun ? "DRY RUN (no upload)" : "FULL INGESTION"}`));
  console.log(chalk.gray(`  Embedding model: ${args.model}`));
  console.log(chalk.gray(`  Window: ${args.windowSize} tokens, overlap: ${args.overlap} tokens`));
  console.log(chalk.gray(`  LLM chunking: ${args.useLlmChunking ? "ENABLED" : "disabled"}`));
  console.log();

  // Discover knowledge files.
  const pattern = args.file
    ? path.join(KNOWLEDGE_DIR, args.file)
    : path.join(KNOWLEDGE_DIR, "*.md");

  const files = await glob(pattern);
  files.sort();

  if (files.length === 0) {
    console.error(chalk.red(`  No markdown files found matching: ${pattern}`));
    process.exit(1);
  }

  console.log(chalk.cyan(`  Found ${files.length} knowledge file(s):\n`));
  for (const f of files) {
    console.log(chalk.gray(`    - ${path.basename(f)}`));
  }
  console.log();

  // Initialise clients.
  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  const dimensions = getEmbeddingDimensions(args.model, args.dimensions);

  let store: PineconeStore | null = null;
  if (!args.dryRun) {
    store = new PineconeStore({
      apiKey: process.env.PINECONE_API_KEY!,
      indexName: process.env.PINECONE_INDEX_NAME!,
      indexHost: process.env.PINECONE_INDEX_HOST,
      dimensions,
    });
  }

  // Process each file.
  const chunkerConfig: Partial<ChunkerConfig> = {
    windowSize: args.windowSize,
    overlap: args.overlap,
    minChunkTokens: args.minChunkTokens,
    useLlmChunking: args.useLlmChunking,
  };

  const embedderConfig: Partial<EmbedderConfig> = {
    model: args.model,
    dimensions: args.dimensions,
    cachePath: path.join(RAG_DIR, ".cache", "embeddings.json"),
  };

  let totalChunks = 0;
  let totalTokens = 0;
  let totalVectors = 0;
  let totalEmbeddingTokens = 0;
  let totalEmbeddingCost = 0;

  const startTime = Date.now();

  for (let fileIdx = 0; fileIdx < files.length; fileIdx++) {
    const filePath = files[fileIdx];
    const filename = path.basename(filePath);

    console.log(chalk.bold(`  [${fileIdx + 1}/${files.length}] Processing ${chalk.cyan(filename)}`));

    // Read file.
    const markdown = fs.readFileSync(filePath, "utf-8");
    const fileTokens = countTokens(markdown);
    console.log(chalk.gray(`    Document: ${fileTokens.toLocaleString()} tokens, ${markdown.length.toLocaleString()} chars`));

    // Chunk.
    const chunks = await chunkDocument(markdown, filename, chunkerConfig, openai);
    const chunkTokens = chunks.reduce((sum, c) => sum + c.tokenCount, 0);
    totalChunks += chunks.length;
    totalTokens += chunkTokens;

    console.log(chalk.green(`    Chunks: ${chunks.length} (${chunkTokens.toLocaleString()} tokens total)`));

    // Token distribution.
    const tokenCounts = chunks.map((c) => c.tokenCount);
    const minT = Math.min(...tokenCounts);
    const maxT = Math.max(...tokenCounts);
    const avgT = Math.round(chunkTokens / chunks.length);
    console.log(chalk.gray(`    Token distribution: min=${minT}, max=${maxT}, avg=${avgT}`));

    if (args.dryRun) {
      // Show estimated cost.
      const estCost = estimateEmbeddingCost(chunkTokens, args.model);
      console.log(chalk.yellow(`    Estimated embedding cost: ${formatCost(estCost)}`));
      console.log();
      continue;
    }

    // Embed.
    console.log(chalk.gray(`    Embedding chunks...`));
    const { embedded, stats } = await embedChunks(chunks, openai, embedderConfig, (cur, tot) => {
      printProgress(cur, tot, "Embedding");
    });
    totalEmbeddingTokens += stats.totalTokens;
    totalEmbeddingCost += stats.estimatedCost;

    console.log(chalk.gray(`    ${stats.cachedChunks} from cache, ${stats.apiChunks} via API`));

    // Upsert to Pinecone.
    console.log(chalk.gray(`    Upserting to Pinecone...`));
    const upserted = await store!.upsertChunks(embedded, (cur, tot) => {
      printProgress(cur, tot, "Upserting");
    });
    totalVectors += upserted;
    console.log(chalk.green(`    Upserted ${upserted} vectors`));
    console.log();
  }

  // Final summary.
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);

  console.log(chalk.bold.blue("\n  Ingestion Complete\n"));
  console.log(chalk.white(`  Files processed:   ${files.length}`));
  console.log(chalk.white(`  Total chunks:      ${totalChunks}`));
  console.log(chalk.white(`  Total tokens:      ${totalTokens.toLocaleString()}`));

  if (args.dryRun) {
    const totalEstCost = estimateEmbeddingCost(totalTokens, args.model);
    console.log(chalk.yellow(`  Est. embed cost:   ${formatCost(totalEstCost)}`));
    console.log(chalk.gray(`  (Dry run — nothing was uploaded)`));
  } else {
    console.log(chalk.white(`  Vectors upserted:  ${totalVectors}`));
    console.log(chalk.white(`  Embedding tokens:  ${totalEmbeddingTokens.toLocaleString()}`));
    console.log(chalk.white(`  Embedding cost:    ${formatCost(totalEmbeddingCost)}`));
    console.log(chalk.white(`  Pinecone index:    ${store!.indexName}`));
    console.log(chalk.white(`  Namespace:         ${store!.namespace}`));
  }

  console.log(chalk.gray(`  Duration:          ${elapsed}s\n`));
}

main().catch((err) => {
  console.error(chalk.red(`\n  Fatal error: ${err instanceof Error ? err.message : String(err)}\n`));
  if (err instanceof Error && err.stack) {
    console.error(chalk.gray(err.stack));
  }
  process.exit(1);
});
