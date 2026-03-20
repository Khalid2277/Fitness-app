/**
 * OpenAI embedding generation with batching, caching, and rate-limit handling.
 *
 * Supports text-embedding-3-small (1536 dims) and text-embedding-3-large (3072 dims).
 * Caches embeddings locally to avoid redundant API calls on re-runs.
 */

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import OpenAI from "openai";
import { countTokens, withRetry, RateLimiter, formatCost } from "./utils.js";
import type { Chunk } from "./chunker.js";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** An embedding result paired with its chunk. */
export interface EmbeddedChunk {
  chunk: Chunk;
  embedding: number[];
}

/** Shape of a single cache entry. */
interface CacheEntry {
  hash: string;
  embedding: number[];
}

/** Configuration for the embedder. */
export interface EmbedderConfig {
  /** Embedding model name. Default "text-embedding-3-small". */
  model: string;
  /** Embedding dimensions (only used for text-embedding-3-* models). */
  dimensions?: number;
  /** Maximum texts per embedding API request. Default 2048. */
  batchSize: number;
  /** Maximum tokens per individual text. Texts exceeding this are truncated. Default 8191. */
  maxTokensPerText: number;
  /** Path to the embedding cache JSON file. */
  cachePath: string;
  /** Requests per minute limit for the embedding API. Default 500. */
  rpmLimit: number;
}

const DEFAULT_CONFIG: EmbedderConfig = {
  model: "text-embedding-3-small",
  dimensions: undefined,
  batchSize: 2048,
  maxTokensPerText: 8191,
  cachePath: path.join(process.cwd(), ".cache", "embeddings.json"),
  rpmLimit: 500,
};

/** Dimensions for known models. */
const MODEL_DIMENSIONS: Record<string, number> = {
  "text-embedding-3-small": 1536,
  "text-embedding-3-large": 3072,
  "text-embedding-ada-002": 1536,
};

// ---------------------------------------------------------------------------
// Cache
// ---------------------------------------------------------------------------

/** Simple JSON-file embedding cache keyed by content hash. */
class EmbeddingCache {
  private entries: Map<string, number[]> = new Map();
  private readonly filePath: string;

  constructor(filePath: string) {
    this.filePath = filePath;
    this.load();
  }

  /** Load cache from disk if it exists. */
  private load(): void {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, "utf-8");
        const data = JSON.parse(raw) as CacheEntry[];
        for (const entry of data) {
          this.entries.set(entry.hash, entry.embedding);
        }
      }
    } catch {
      // Start fresh on any parse error.
      this.entries.clear();
    }
  }

  /** Persist cache to disk. */
  save(): void {
    const dir = path.dirname(this.filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    const data: CacheEntry[] = [];
    for (const [hash, embedding] of this.entries) {
      data.push({ hash, embedding });
    }
    fs.writeFileSync(this.filePath, JSON.stringify(data));
  }

  /** Get a cached embedding by content hash. */
  get(hash: string): number[] | undefined {
    return this.entries.get(hash);
  }

  /** Store an embedding in the cache. */
  set(hash: string, embedding: number[]): void {
    this.entries.set(hash, embedding);
  }

  /** Number of cached entries. */
  get size(): number {
    return this.entries.size;
  }
}

/** Create a stable hash for a chunk's content + model combination. */
function chunkHash(text: string, model: string, dimensions?: number): string {
  const input = `${model}:${dimensions ?? "default"}:${text}`;
  return crypto.createHash("sha256").update(input).digest("hex").slice(0, 16);
}

// ---------------------------------------------------------------------------
// Embedder
// ---------------------------------------------------------------------------

/**
 * Generate embeddings for an array of chunks using OpenAI's embedding API.
 *
 * Features:
 * - Batches requests (up to batchSize texts per call).
 * - Caches embeddings to avoid re-embedding unchanged chunks.
 * - Handles rate limiting with exponential backoff.
 * - Truncates texts exceeding maxTokensPerText.
 *
 * @param chunks - Array of Chunk objects to embed.
 * @param openai - OpenAI client instance.
 * @param config - Partial configuration (merged with defaults).
 * @param onProgress - Optional callback (current, total) for progress reporting.
 * @returns Array of EmbeddedChunk with embeddings attached.
 */
export async function embedChunks(
  chunks: Chunk[],
  openai: OpenAI,
  config: Partial<EmbedderConfig> = {},
  onProgress?: (current: number, total: number) => void,
): Promise<{ embedded: EmbeddedChunk[]; stats: EmbeddingStats }> {
  const cfg: EmbedderConfig = { ...DEFAULT_CONFIG, ...config };
  const cache = new EmbeddingCache(cfg.cachePath);
  const rateLimiter = new RateLimiter(cfg.rpmLimit);

  const results: EmbeddedChunk[] = [];
  let cachedCount = 0;
  let apiTokens = 0;
  let apiCalls = 0;

  // Separate cached vs uncached chunks.
  const uncached: { index: number; chunk: Chunk; hash: string }[] = [];

  for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    const hash = chunkHash(chunk.text, cfg.model, cfg.dimensions);
    const cached = cache.get(hash);
    if (cached) {
      results.push({ chunk, embedding: cached });
      cachedCount++;
    } else {
      uncached.push({ index: i, chunk, hash });
    }
  }

  // Batch-embed uncached chunks.
  for (let batchStart = 0; batchStart < uncached.length; batchStart += cfg.batchSize) {
    const batch = uncached.slice(batchStart, batchStart + cfg.batchSize);

    // Prepare texts, truncating if necessary.
    const texts = batch.map((item) => {
      const tokens = countTokens(item.chunk.text);
      if (tokens > cfg.maxTokensPerText) {
        // Truncate by taking roughly maxTokensPerText worth of characters.
        // A rough heuristic: 1 token ~= 4 characters for English.
        const approxChars = cfg.maxTokensPerText * 4;
        return item.chunk.text.slice(0, approxChars);
      }
      return item.chunk.text;
    });

    // Track token usage.
    const batchTokens = texts.reduce((sum, t) => sum + countTokens(t), 0);
    apiTokens += batchTokens;

    await rateLimiter.acquire();
    apiCalls++;

    const response = await withRetry(async () => {
      const params: OpenAI.Embeddings.EmbeddingCreateParams = {
        model: cfg.model,
        input: texts,
      };
      if (cfg.dimensions && cfg.model.startsWith("text-embedding-3-")) {
        params.dimensions = cfg.dimensions;
      }
      return openai.embeddings.create(params);
    });

    for (let j = 0; j < batch.length; j++) {
      const embedding = response.data[j].embedding;
      const item = batch[j];
      cache.set(item.hash, embedding);
      results.push({ chunk: item.chunk, embedding });
    }

    onProgress?.(Math.min(batchStart + cfg.batchSize, uncached.length) + cachedCount, chunks.length);
  }

  // Save cache to disk.
  cache.save();

  // Sort results back to original order.
  const chunkIdToOrder = new Map(chunks.map((c, i) => [c.id, i]));
  results.sort((a, b) => (chunkIdToOrder.get(a.chunk.id) ?? 0) - (chunkIdToOrder.get(b.chunk.id) ?? 0));

  const dims = cfg.dimensions ?? MODEL_DIMENSIONS[cfg.model] ?? 1536;
  const stats: EmbeddingStats = {
    totalChunks: chunks.length,
    cachedChunks: cachedCount,
    apiChunks: uncached.length,
    apiCalls,
    totalTokens: apiTokens,
    estimatedCost: estimateCost(apiTokens, cfg.model),
    dimensions: dims,
    model: cfg.model,
  };

  return { embedded: results, stats };
}

/** Embedding run statistics. */
export interface EmbeddingStats {
  totalChunks: number;
  cachedChunks: number;
  apiChunks: number;
  apiCalls: number;
  totalTokens: number;
  estimatedCost: number;
  dimensions: number;
  model: string;
}

/** Price per 1M tokens for embedding models. */
function estimateCost(tokens: number, model: string): number {
  const prices: Record<string, number> = {
    "text-embedding-3-small": 0.02,
    "text-embedding-3-large": 0.13,
    "text-embedding-ada-002": 0.10,
  };
  const pricePerMillion = prices[model] ?? 0.02;
  return (tokens / 1_000_000) * pricePerMillion;
}

/**
 * Get the output dimensions for a given embedding model and optional dimension override.
 * @param model - Embedding model name.
 * @param dimensions - Optional dimension override (for text-embedding-3-* models).
 * @returns The output dimension count.
 */
export function getEmbeddingDimensions(model: string, dimensions?: number): number {
  if (dimensions && model.startsWith("text-embedding-3-")) return dimensions;
  return MODEL_DIMENSIONS[model] ?? 1536;
}

/**
 * Format embedding stats as a human-readable summary string.
 * @param stats - EmbeddingStats to format.
 * @returns Multi-line summary string.
 */
export function formatEmbeddingStats(stats: EmbeddingStats): string {
  const lines = [
    `  Model: ${stats.model} (${stats.dimensions} dims)`,
    `  Total chunks: ${stats.totalChunks}`,
    `  From cache: ${stats.cachedChunks}`,
    `  API embedded: ${stats.apiChunks}`,
    `  API calls: ${stats.apiCalls}`,
    `  Tokens used: ${stats.totalTokens.toLocaleString()}`,
    `  Estimated cost: ${formatCost(stats.estimatedCost)}`,
  ];
  return lines.join("\n");
}
