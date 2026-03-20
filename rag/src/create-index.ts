#!/usr/bin/env node
/**
 * One-time script to create the Pinecone index for the AlfaNutrition RAG system.
 *
 * Usage:
 *   npm run create-index
 *   npm run create-index -- --dimensions 3072   # for text-embedding-3-large
 */

import path from "node:path";
import { fileURLToPath } from "node:url";
import chalk from "chalk";
import dotenv from "dotenv";

import { PineconeStore } from "./pinecone-store.js";
import { getEmbeddingDimensions } from "./embedder.js";

// ---------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, "..", "..");

dotenv.config({ path: path.join(ROOT_DIR, ".env") });

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

function parseDimensions(): number {
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--dimensions" && args[i + 1]) {
      return parseInt(args[i + 1], 10);
    }
  }
  const model = process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small";
  const envDims = process.env.OPENAI_EMBEDDING_DIMENSIONS
    ? parseInt(process.env.OPENAI_EMBEDDING_DIMENSIONS, 10)
    : undefined;
  return getEmbeddingDimensions(model, envDims);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log(chalk.bold.blue("\n  AlfaNutrition — Create Pinecone Index\n"));

  // Validate env vars.
  if (!process.env.PINECONE_API_KEY) {
    console.error(chalk.red("  Error: PINECONE_API_KEY is not set in .env"));
    process.exit(1);
  }
  if (!process.env.PINECONE_INDEX_NAME) {
    console.error(chalk.red("  Error: PINECONE_INDEX_NAME is not set in .env"));
    process.exit(1);
  }

  const indexName = process.env.PINECONE_INDEX_NAME;
  const dimensions = parseDimensions();
  const model = process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small";

  console.log(chalk.gray(`  Index name:   ${indexName}`));
  console.log(chalk.gray(`  Dimensions:   ${dimensions}`));
  console.log(chalk.gray(`  Metric:       cosine`));
  console.log(chalk.gray(`  Embed model:  ${model}`));
  console.log();

  const store = new PineconeStore({
    apiKey: process.env.PINECONE_API_KEY,
    indexName,
    indexHost: process.env.PINECONE_INDEX_HOST,
    dimensions,
    metric: "cosine",
  });

  console.log(chalk.gray("  Checking if index exists..."));
  const created = await store.createIndexIfNotExists();

  if (created) {
    console.log(chalk.green(`  Index "${indexName}" created successfully!`));
  } else {
    console.log(chalk.yellow(`  Index "${indexName}" already exists.`));
  }

  // Verify configuration.
  console.log(chalk.gray("\n  Verifying index configuration..."));
  const desc = await store.describeIndex();

  console.log(chalk.white(`\n  Index details:`));
  console.log(chalk.gray(`    Name:       ${desc.name}`));
  console.log(chalk.gray(`    Dimension:  ${desc.dimension}`));
  console.log(chalk.gray(`    Metric:     ${desc.metric}`));
  console.log(chalk.gray(`    Status:     ${desc.status?.ready ? "Ready" : "Not ready"}`));
  console.log(chalk.gray(`    Host:       ${desc.host ?? "N/A"}`));

  // Get stats.
  try {
    const stats = await store.getStats();
    console.log(chalk.gray(`    Vectors:    ${stats.totalRecordCount ?? 0}`));
    console.log(chalk.gray(`    Namespaces: ${Object.keys(stats.namespaces ?? {}).length}`));
  } catch {
    console.log(chalk.gray(`    (Stats not available yet — index may still be initializing)`));
  }

  if (desc.host && !process.env.PINECONE_INDEX_HOST) {
    console.log(chalk.yellow(`\n  Tip: Add this to your .env for faster connections:`));
    console.log(chalk.white(`    PINECONE_INDEX_HOST=${desc.host}`));
  }

  console.log();
}

main().catch((err) => {
  console.error(chalk.red(`\n  Fatal error: ${err instanceof Error ? err.message : String(err)}\n`));
  process.exit(1);
});
