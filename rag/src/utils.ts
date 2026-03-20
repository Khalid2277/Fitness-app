/**
 * Shared utilities for the RAG ingestion pipeline.
 * Token counting, markdown parsing, cost estimation, rate limiting.
 */

import { encoding_for_model } from "tiktoken";

// ---------------------------------------------------------------------------
// Token counting
// ---------------------------------------------------------------------------

let _encoder: ReturnType<typeof encoding_for_model> | null = null;

/** Lazily initialise the cl100k_base encoder used by OpenAI embedding models. */
function getEncoder() {
  if (!_encoder) {
    _encoder = encoding_for_model("gpt-4");          // cl100k_base
  }
  return _encoder;
}

/**
 * Count the number of tokens in a string using the cl100k_base tokenizer.
 * @param text - The text to tokenize.
 * @returns Token count.
 */
export function countTokens(text: string): number {
  const enc = getEncoder();
  const tokens = enc.encode(text);
  return tokens.length;
}

/**
 * Encode text to token IDs.
 * @param text - The text to encode.
 * @returns Array of token IDs.
 */
export function encodeTokens(text: string): number[] {
  const enc = getEncoder();
  return Array.from(enc.encode(text));
}

/**
 * Decode token IDs back to text.
 * @param tokens - Array of token IDs.
 * @returns Decoded text string.
 */
export function decodeTokens(tokens: number[]): string {
  const enc = getEncoder();
  return new TextDecoder().decode(enc.decode(new Uint32Array(tokens)));
}

// ---------------------------------------------------------------------------
// Markdown parsing
// ---------------------------------------------------------------------------

/** Represents a parsed section of a markdown document. */
export interface MarkdownSection {
  heading: string;
  level: number;            // 1 = #, 2 = ##, etc.
  content: string;          // raw text content under this heading
  startLine: number;
  endLine: number;
}

/**
 * Parse a markdown document into a flat list of sections.
 * Each section spans from one heading to the next heading of equal or higher level.
 * @param markdown - Raw markdown text.
 * @returns Array of sections in document order.
 */
export function parseMarkdownSections(markdown: string): MarkdownSection[] {
  const lines = markdown.split("\n");
  const sections: MarkdownSection[] = [];

  let currentHeading = "";
  let currentLevel = 0;
  let currentStart = 0;
  const contentLines: string[] = [];

  function flush(endLine: number) {
    if (currentHeading || contentLines.length > 0) {
      sections.push({
        heading: currentHeading,
        level: currentLevel,
        content: contentLines.join("\n").trim(),
        startLine: currentStart,
        endLine,
      });
    }
    contentLines.length = 0;
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const headingMatch = line.match(/^(#{1,6})\s+(.*)/);
    if (headingMatch) {
      flush(i - 1);
      currentLevel = headingMatch[1].length;
      currentHeading = headingMatch[2].trim();
      currentStart = i;
    } else {
      contentLines.push(line);
    }
  }
  flush(lines.length - 1);

  return sections;
}

/**
 * Extract all headings from markdown text.
 * @param markdown - Raw markdown string.
 * @returns Array of {level, text} objects.
 */
export function extractHeadings(markdown: string): { level: number; text: string }[] {
  const headings: { level: number; text: string }[] = [];
  for (const line of markdown.split("\n")) {
    const m = line.match(/^(#{1,6})\s+(.*)/);
    if (m) {
      headings.push({ level: m[1].length, text: m[2].trim() });
    }
  }
  return headings;
}

/**
 * Get the first sentence of each paragraph in a markdown string.
 * Useful for generating a document outline for LLM-based chunking.
 * @param markdown - Raw markdown string.
 * @returns Array of first-sentences, one per paragraph.
 */
export function extractFirstSentences(markdown: string): string[] {
  const paragraphs = markdown.split(/\n{2,}/);
  const sentences: string[] = [];
  for (const p of paragraphs) {
    const trimmed = p.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const sentenceMatch = trimmed.match(/^[^.!?]*[.!?]/);
    sentences.push(sentenceMatch ? sentenceMatch[0].trim() : trimmed.slice(0, 120));
  }
  return sentences;
}

// ---------------------------------------------------------------------------
// Cost estimation
// ---------------------------------------------------------------------------

/** Price per 1M tokens for OpenAI embedding models (USD). */
const EMBEDDING_PRICES: Record<string, number> = {
  "text-embedding-3-small": 0.02,
  "text-embedding-3-large": 0.13,
  "text-embedding-ada-002": 0.10,
};

/**
 * Estimate the dollar cost of embedding a given number of tokens.
 * @param tokenCount - Total tokens to embed.
 * @param model - Embedding model name.
 * @returns Estimated cost in USD.
 */
export function estimateEmbeddingCost(tokenCount: number, model: string): number {
  const pricePerMillion = EMBEDDING_PRICES[model] ?? 0.02;
  return (tokenCount / 1_000_000) * pricePerMillion;
}

/**
 * Format a cost value as a human-readable USD string.
 * @param cost - Dollar amount.
 * @returns Formatted string like "$0.0042".
 */
export function formatCost(cost: number): string {
  if (cost < 0.01) return `$${cost.toFixed(4)}`;
  return `$${cost.toFixed(2)}`;
}

// ---------------------------------------------------------------------------
// Progress display
// ---------------------------------------------------------------------------

/**
 * Print a simple text progress bar to stdout.
 * @param current - Current step (0-based).
 * @param total - Total steps.
 * @param label - Optional label to display before the bar.
 */
export function printProgress(current: number, total: number, label = ""): void {
  const width = 30;
  const pct = Math.min(current / total, 1);
  const filled = Math.round(width * pct);
  const bar = "\u2588".repeat(filled) + "\u2591".repeat(width - filled);
  const pctStr = (pct * 100).toFixed(0).padStart(3);
  process.stdout.write(`\r  ${label} [${bar}] ${pctStr}% (${current}/${total})`);
  if (current >= total) process.stdout.write("\n");
}

// ---------------------------------------------------------------------------
// Rate limiter
// ---------------------------------------------------------------------------

/**
 * Token-bucket rate limiter with exponential backoff on 429 responses.
 * Tracks request count within a rolling time window.
 */
export class RateLimiter {
  private timestamps: number[] = [];
  private readonly maxRequests: number;
  private readonly windowMs: number;

  /**
   * @param maxRequests - Maximum requests allowed within the window.
   * @param windowMs - Time window in milliseconds (default 60 000 = 1 minute).
   */
  constructor(maxRequests: number, windowMs = 60_000) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
  }

  /** Wait until a request slot is available. */
  async acquire(): Promise<void> {
    while (true) {
      const now = Date.now();
      this.timestamps = this.timestamps.filter((t) => now - t < this.windowMs);
      if (this.timestamps.length < this.maxRequests) {
        this.timestamps.push(now);
        return;
      }
      const oldestInWindow = this.timestamps[0];
      const waitMs = oldestInWindow + this.windowMs - now + 50;
      await sleep(waitMs);
    }
  }
}

/**
 * Execute a function with exponential backoff retry.
 * @param fn - Async function to execute.
 * @param maxRetries - Maximum number of retries (default 5).
 * @param baseDelayMs - Base delay in ms that doubles each retry (default 1000).
 * @returns The resolved value of fn.
 */
export async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 5,
  baseDelayMs = 1000,
): Promise<T> {
  let lastError: unknown;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err: unknown) {
      lastError = err;
      if (attempt === maxRetries) break;

      const errMsg = err instanceof Error ? err.message : String(err);
      const isRateLimited =
        errMsg.includes("429") ||
        errMsg.toLowerCase().includes("rate limit") ||
        errMsg.toLowerCase().includes("too many requests");
      const isTransient =
        errMsg.includes("500") ||
        errMsg.includes("502") ||
        errMsg.includes("503") ||
        errMsg.includes("timeout");

      if (!isRateLimited && !isTransient) throw err;

      const delay = baseDelayMs * Math.pow(2, attempt) + Math.random() * 500;
      console.warn(
        `  Retry ${attempt + 1}/${maxRetries} after ${Math.round(delay)}ms: ${errMsg.slice(0, 100)}`,
      );
      await sleep(delay);
    }
  }
  throw lastError;
}

/** Simple async sleep helper. */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// File category mapping
// ---------------------------------------------------------------------------

/** Map a knowledge document filename to a category slug. */
export function categoryFromFilename(filename: string): string {
  const name = filename.replace(/^\d+_/, "").replace(/\.md$/, "");
  return name.toLowerCase().replace(/\s+/g, "_");
}

/**
 * Generate a deterministic chunk ID from file + chunk index.
 * @param sourceFile - Filename without extension.
 * @param chunkIndex - 0-based index within the file.
 * @returns Stable string ID suitable for Pinecone vector IDs.
 */
export function chunkId(sourceFile: string, chunkIndex: number): string {
  return `${sourceFile}::chunk_${String(chunkIndex).padStart(4, "0")}`;
}
