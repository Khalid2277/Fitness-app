#!/usr/bin/env node
/**
 * Preview/test chunking without embedding or uploading.
 * Useful for tuning chunk size parameters.
 *
 * Usage:
 *   npm run chunk-preview                                # All files
 *   npm run chunk-preview -- --file 01_exercise_science.md
 *   npm run chunk-preview -- --window-size 256 --overlap 64
 *   npm run chunk-preview -- --show-text                 # Print full chunk text
 *   npm run chunk-preview -- --show-metadata             # Print metadata per chunk
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { glob } from "glob";
import chalk from "chalk";
import dotenv from "dotenv";

import { chunkDocument, type ChunkerConfig, type Chunk } from "./chunker.js";
import { countTokens, estimateEmbeddingCost, formatCost } from "./utils.js";

// ---------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "..", "..");
const RAG_DIR = path.resolve(__dirname, "..");
const KNOWLEDGE_DIR = path.join(RAG_DIR, "knowledge");

dotenv.config({ path: path.join(ROOT_DIR, ".env") });

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

interface PreviewArgs {
  file?: string;
  windowSize: number;
  overlap: number;
  minChunkTokens: number;
  showText: boolean;
  showMetadata: boolean;
}

function parseArgs(): PreviewArgs {
  const args = process.argv.slice(2);
  const result: PreviewArgs = {
    windowSize: 512,
    overlap: 128,
    minChunkTokens: 100,
    showText: false,
    showMetadata: false,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--file":
        result.file = args[++i];
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
      case "--show-text":
        result.showText = true;
        break;
      case "--show-metadata":
        result.showMetadata = true;
        break;
      case "--help":
      case "-h":
        console.log(`
${chalk.bold("Chunk Preview Tool")}

${chalk.yellow("Options:")}
  --file <name>          Process a single file
  --window-size <n>      Token window size (default: 512)
  --overlap <n>          Token overlap (default: 128)
  --min-chunk-tokens <n> Minimum chunk tokens (default: 100)
  --show-text            Print full chunk text
  --show-metadata        Print metadata for each chunk
`);
        process.exit(0);
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Histogram
// ---------------------------------------------------------------------------

function printHistogram(values: number[], label: string, bucketCount = 10): void {
  if (values.length === 0) return;

  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = max - min || 1;
  const bucketSize = range / bucketCount;
  const buckets = new Array<number>(bucketCount).fill(0);

  for (const v of values) {
    const idx = Math.min(Math.floor((v - min) / bucketSize), bucketCount - 1);
    buckets[idx]++;
  }

  const maxCount = Math.max(...buckets);
  const barWidth = 30;

  console.log(chalk.bold(`\n  ${label} Distribution:`));
  for (let i = 0; i < bucketCount; i++) {
    const lo = Math.round(min + i * bucketSize);
    const hi = Math.round(min + (i + 1) * bucketSize);
    const count = buckets[i];
    const bar = "\u2588".repeat(Math.round((count / maxCount) * barWidth));
    const rangeLabel = `${String(lo).padStart(5)}-${String(hi).padStart(5)}`;
    console.log(chalk.gray(`    ${rangeLabel} |`) + chalk.cyan(bar) + chalk.gray(` ${count}`));
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const args = parseArgs();

  console.log(chalk.bold.blue("\n  AlfaNutrition — Chunk Preview\n"));
  console.log(chalk.gray(`  Window: ${args.windowSize} tokens, overlap: ${args.overlap} tokens`));
  console.log(chalk.gray(`  Min chunk: ${args.minChunkTokens} tokens`));
  console.log();

  // Discover files.
  const pattern = args.file
    ? path.join(KNOWLEDGE_DIR, args.file)
    : path.join(KNOWLEDGE_DIR, "*.md");

  const files = await glob(pattern);
  files.sort();

  if (files.length === 0) {
    console.error(chalk.red(`  No files found matching: ${pattern}`));
    process.exit(1);
  }

  const allTokenCounts: number[] = [];
  let grandTotalChunks = 0;
  let grandTotalTokens = 0;

  const chunkerConfig: Partial<ChunkerConfig> = {
    windowSize: args.windowSize,
    overlap: args.overlap,
    minChunkTokens: args.minChunkTokens,
    useLlmChunking: false,
  };

  for (const filePath of files) {
    const filename = path.basename(filePath);
    const markdown = fs.readFileSync(filePath, "utf-8");
    const fileTokens = countTokens(markdown);

    console.log(chalk.bold(`  ${chalk.cyan(filename)}`));
    console.log(chalk.gray(`    Document: ${fileTokens.toLocaleString()} tokens`));

    const chunks = await chunkDocument(markdown, filename, chunkerConfig);
    const chunkTokens = chunks.reduce((sum, c) => sum + c.tokenCount, 0);

    grandTotalChunks += chunks.length;
    grandTotalTokens += chunkTokens;

    const tokenCounts = chunks.map((c) => c.tokenCount);
    allTokenCounts.push(...tokenCounts);

    const minT = Math.min(...tokenCounts);
    const maxT = Math.max(...tokenCounts);
    const avgT = Math.round(chunkTokens / chunks.length);

    console.log(chalk.green(`    Chunks: ${chunks.length}`));
    console.log(chalk.gray(`    Tokens: total=${chunkTokens.toLocaleString()}, min=${minT}, max=${maxT}, avg=${avgT}`));

    // Metadata summary.
    const allMuscles = new Set<string>();
    const allExercises = new Set<string>();
    const allTopics = new Set<string>();
    for (const c of chunks) {
      c.metadata.muscle_groups.forEach((m) => allMuscles.add(m));
      c.metadata.exercise_names.forEach((e) => allExercises.add(e));
      c.metadata.topic_tags.forEach((t) => allTopics.add(t));
    }

    if (allMuscles.size > 0) {
      console.log(chalk.gray(`    Muscles: ${Array.from(allMuscles).join(", ")}`));
    }
    if (allExercises.size > 0) {
      console.log(chalk.gray(`    Exercises: ${Array.from(allExercises).slice(0, 10).join(", ")}${allExercises.size > 10 ? ` (+${allExercises.size - 10} more)` : ""}`));
    }
    if (allTopics.size > 0) {
      console.log(chalk.gray(`    Topics: ${Array.from(allTopics).join(", ")}`));
    }

    // Per-chunk detail.
    if (args.showText || args.showMetadata) {
      console.log();
      for (const chunk of chunks) {
        console.log(chalk.yellow(`    --- ${chunk.id} (${chunk.tokenCount} tokens) ---`));
        if (args.showMetadata) {
          console.log(chalk.gray(`    Section: ${chunk.metadata.section}${chunk.metadata.subsection ? " > " + chunk.metadata.subsection : ""}`));
          if (chunk.metadata.muscle_groups.length > 0) {
            console.log(chalk.gray(`    Muscles: ${chunk.metadata.muscle_groups.join(", ")}`));
          }
          if (chunk.metadata.exercise_names.length > 0) {
            console.log(chalk.gray(`    Exercises: ${chunk.metadata.exercise_names.join(", ")}`));
          }
          if (chunk.metadata.topic_tags.length > 0) {
            console.log(chalk.gray(`    Topics: ${chunk.metadata.topic_tags.join(", ")}`));
          }
          if (chunk.metadata.has_numbers) {
            console.log(chalk.gray(`    Has specific numbers/recommendations`));
          }
        }
        if (args.showText) {
          const preview = chunk.text.length > 500
            ? chunk.text.slice(0, 500) + "..."
            : chunk.text;
          console.log(chalk.white(`    ${preview.replace(/\n/g, "\n    ")}`));
        }
        console.log();
      }
    }

    console.log();
  }

  // Histogram.
  printHistogram(allTokenCounts, "Token Count");

  // Grand totals.
  const model = process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small";
  const estCost = estimateEmbeddingCost(grandTotalTokens, model);

  console.log(chalk.bold.blue("\n  Summary\n"));
  console.log(chalk.white(`  Files:          ${files.length}`));
  console.log(chalk.white(`  Total chunks:   ${grandTotalChunks}`));
  console.log(chalk.white(`  Total tokens:   ${grandTotalTokens.toLocaleString()}`));
  console.log(chalk.white(`  Avg tokens:     ${Math.round(grandTotalTokens / grandTotalChunks)}`));
  console.log(chalk.yellow(`  Est. embed cost (${model}): ${formatCost(estCost)}`));
  console.log();
}

main().catch((err) => {
  console.error(chalk.red(`\n  Error: ${err instanceof Error ? err.message : String(err)}\n`));
  process.exit(1);
});
