/**
 * Sliding-window + LLM-based semantic chunking for fitness knowledge documents.
 *
 * Two strategies:
 * 1. Sliding window  — token-based windows that respect markdown section boundaries.
 * 2. LLM refinement  — optional pass that scores chunk coherence and re-splits bad ones.
 *
 * Hybrid flow:
 *   sliding window -> (optional) LLM coherence scoring -> re-split low scorers -> merge runts
 */

import OpenAI from "openai";
import {
  countTokens,
  encodeTokens,
  decodeTokens,
  parseMarkdownSections,
  extractHeadings,
  extractFirstSentences,
} from "./utils.js";
import { buildChunkMetadata, type ChunkMetadata } from "./metadata-extractor.js";
import { categoryFromFilename, chunkId as makeChunkId } from "./utils.js";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** A single processed chunk ready for embedding. */
export interface Chunk {
  id: string;
  text: string;
  tokenCount: number;
  metadata: ChunkMetadata;
}

/** Configuration for the chunking pipeline. */
export interface ChunkerConfig {
  /** Target window size in tokens. Default 512. */
  windowSize: number;
  /** Overlap in tokens between consecutive windows. Default 128. */
  overlap: number;
  /** Minimum chunk size in tokens — chunks smaller than this get merged. Default 100. */
  minChunkTokens: number;
  /** Coherence threshold (0-1) — chunks below this are re-split by the LLM pass. Default 0.6. */
  coherenceThreshold: number;
  /** Whether to run the LLM-based refinement pass. Default false. */
  useLlmChunking: boolean;
  /** OpenAI model for LLM chunking. Default "gpt-4o-mini". */
  llmModel: string;
}

const DEFAULT_CONFIG: ChunkerConfig = {
  windowSize: 512,
  overlap: 128,
  minChunkTokens: 100,
  coherenceThreshold: 0.6,
  useLlmChunking: false,
  llmModel: "gpt-4o-mini",
};

// ---------------------------------------------------------------------------
// Strategy 1: Sliding Window Chunking
// ---------------------------------------------------------------------------

/**
 * Split text into overlapping token windows that respect markdown structure.
 *
 * Priority for split boundaries (highest to lowest):
 *   1. Markdown heading boundaries (##, ###, etc.)
 *   2. Paragraph boundaries (double newline)
 *   3. Sentence boundaries (. ! ?)
 *   4. Word boundaries (space)
 *   5. Hard token cut (last resort)
 *
 * @param text - Full markdown document text.
 * @param windowSize - Target window size in tokens.
 * @param overlap - Number of overlapping tokens between consecutive windows.
 * @returns Array of {text, startOffset} tuples where startOffset is char position.
 */
export function slidingWindowChunk(
  text: string,
  windowSize: number,
  overlap: number,
): { text: string; startOffset: number }[] {
  const sections = parseMarkdownSections(text);
  const results: { text: string; startOffset: number }[] = [];

  // Accumulate sections into chunks, respecting the token budget.
  let buffer = "";
  let bufferStartOffset = 0;
  let isFirstBuffer = true;

  function flushBuffer() {
    if (!buffer.trim()) return;
    // The buffer may itself be larger than windowSize if a single section is huge.
    const subChunks = splitLargeText(buffer, windowSize, overlap);
    for (const sc of subChunks) {
      results.push({
        text: sc.text,
        startOffset: bufferStartOffset + sc.relativeOffset,
      });
    }
    buffer = "";
  }

  for (const section of sections) {
    const sectionText = section.heading
      ? `${"#".repeat(section.level)} ${section.heading}\n\n${section.content}`
      : section.content;
    const sectionTokens = countTokens(sectionText);

    if (isFirstBuffer) {
      bufferStartOffset = text.indexOf(sectionText);
      if (bufferStartOffset === -1) bufferStartOffset = 0;
      isFirstBuffer = false;
    }

    // If adding this section exceeds the window, flush first.
    if (buffer && countTokens(buffer) + sectionTokens > windowSize) {
      flushBuffer();
      bufferStartOffset = text.indexOf(sectionText, bufferStartOffset);
      if (bufferStartOffset === -1) {
        bufferStartOffset = Math.max(0, text.lastIndexOf(sectionText));
      }
    }

    buffer += (buffer ? "\n\n" : "") + sectionText;
  }
  flushBuffer();

  return results;
}

/**
 * Split a large text block into overlapping windows using sentence/word boundaries.
 * Used when a single markdown section exceeds the window size.
 */
function splitLargeText(
  text: string,
  windowSize: number,
  overlap: number,
): { text: string; relativeOffset: number }[] {
  const totalTokens = countTokens(text);
  if (totalTokens <= windowSize) {
    return [{ text, relativeOffset: 0 }];
  }

  const results: { text: string; relativeOffset: number }[] = [];
  const sentences = splitIntoSentences(text);
  let currentChunk = "";
  let currentStart = 0;
  let charPointer = 0;

  for (let i = 0; i < sentences.length; i++) {
    const sentence = sentences[i];
    const candidate = currentChunk ? currentChunk + " " + sentence : sentence;
    const candidateTokens = countTokens(candidate);

    if (candidateTokens > windowSize && currentChunk) {
      results.push({ text: currentChunk.trim(), relativeOffset: currentStart });

      // Build overlap from the tail of the current chunk.
      const overlapText = buildOverlapPrefix(currentChunk, overlap);
      currentStart = charPointer - overlapText.length;
      if (currentStart < 0) currentStart = 0;
      currentChunk = overlapText + " " + sentence;
    } else {
      if (!currentChunk) currentStart = charPointer;
      currentChunk = candidate;
    }

    charPointer += sentence.length + 1; // +1 for the space/join
  }

  if (currentChunk.trim()) {
    results.push({ text: currentChunk.trim(), relativeOffset: currentStart });
  }

  // If we still have a single giant result, do a hard token-boundary split.
  if (results.length === 1 && countTokens(results[0].text) > windowSize * 1.5) {
    return hardTokenSplit(text, windowSize, overlap);
  }

  return results;
}

/** Split text into sentences, keeping the delimiter attached. */
function splitIntoSentences(text: string): string[] {
  const raw = text.split(/(?<=[.!?])\s+/);
  return raw.filter((s) => s.trim().length > 0);
}

/** Build an overlap prefix of approximately `overlapTokens` tokens from the end of text. */
function buildOverlapPrefix(text: string, overlapTokens: number): string {
  const tokens = encodeTokens(text);
  if (tokens.length <= overlapTokens) return text;
  const overlapIds = tokens.slice(tokens.length - overlapTokens);
  return decodeTokens(overlapIds);
}

/** Last-resort hard split at exact token boundaries. */
function hardTokenSplit(
  text: string,
  windowSize: number,
  overlap: number,
): { text: string; relativeOffset: number }[] {
  const tokens = encodeTokens(text);
  const results: { text: string; relativeOffset: number }[] = [];
  const step = windowSize - overlap;
  let offset = 0;

  for (let start = 0; start < tokens.length; start += step) {
    const end = Math.min(start + windowSize, tokens.length);
    const chunkText = decodeTokens(tokens.slice(start, end));
    results.push({ text: chunkText, relativeOffset: offset });
    offset += decodeTokens(tokens.slice(start, start + step)).length;
    if (end >= tokens.length) break;
  }

  return results;
}

// ---------------------------------------------------------------------------
// Strategy 2: LLM-Based Semantic Chunking (optional refinement)
// ---------------------------------------------------------------------------

interface CoherenceScore {
  chunkIndex: number;
  score: number;
  reason: string;
  suggestedSplitPoint?: string;
}

/**
 * Use an LLM to score the semantic coherence of each chunk.
 * Returns scores between 0 (incoherent mix of topics) and 1 (single focused topic).
 *
 * @param chunks - Array of chunk texts to score.
 * @param openai - OpenAI client instance.
 * @param model - Model to use for scoring.
 * @returns Array of CoherenceScore objects.
 */
async function scoreChunkCoherence(
  chunks: string[],
  openai: OpenAI,
  model: string,
): Promise<CoherenceScore[]> {
  // Process in batches of 5 chunks at a time to stay within context limits.
  const batchSize = 5;
  const allScores: CoherenceScore[] = [];

  for (let i = 0; i < chunks.length; i += batchSize) {
    const batch = chunks.slice(i, i + batchSize);
    const chunkDescriptions = batch
      .map((c, idx) => `--- CHUNK ${i + idx} ---\n${c.slice(0, 800)}\n--- END CHUNK ${i + idx} ---`)
      .join("\n\n");

    const response = await openai.chat.completions.create({
      model,
      temperature: 0,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a text analysis assistant. You evaluate the semantic coherence of text chunks that will be used in a RAG system for a fitness/nutrition knowledge base.

For each chunk, score its coherence from 0 to 1:
- 1.0: Chunk covers a single, focused topic. Perfect for retrieval.
- 0.7-0.9: Mostly one topic with minor tangents. Acceptable.
- 0.4-0.6: Mixed topics. Would benefit from splitting.
- 0.0-0.3: Completely incoherent mix. Must be re-split.

If the score is below 0.6, suggest where the chunk should be split (quote the sentence where the topic changes).

Respond with JSON: { "scores": [ { "chunkIndex": number, "score": number, "reason": string, "suggestedSplitPoint": string | null } ] }`,
        },
        {
          role: "user",
          content: `Score the coherence of these chunks:\n\n${chunkDescriptions}`,
        },
      ],
    });

    const content = response.choices[0]?.message?.content ?? "{}";
    try {
      const parsed = JSON.parse(content) as { scores?: CoherenceScore[] };
      if (parsed.scores) {
        allScores.push(...parsed.scores);
      }
    } catch {
      // If parsing fails, default to passing scores for this batch.
      for (let idx = i; idx < i + batch.length; idx++) {
        allScores.push({ chunkIndex: idx, score: 0.8, reason: "LLM parse error — defaulting to pass" });
      }
    }
  }

  return allScores;
}

/**
 * Ask the LLM to identify optimal semantic split points in a document.
 * Sends the document outline (headings + first sentences) rather than full text.
 *
 * @param markdown - Full markdown document.
 * @param openai - OpenAI client.
 * @param model - Model name.
 * @returns Array of heading texts where major topic boundaries occur.
 */
async function identifySemanticBoundaries(
  markdown: string,
  openai: OpenAI,
  model: string,
): Promise<string[]> {
  const headings = extractHeadings(markdown);
  const firstSentences = extractFirstSentences(markdown);

  const outline = headings
    .map((h) => `${"  ".repeat(h.level - 1)}${"#".repeat(h.level)} ${h.text}`)
    .join("\n");

  const paragraphPreview = firstSentences.slice(0, 30).join("\n");

  const response = await openai.chat.completions.create({
    model,
    temperature: 0,
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content: `You identify semantic topic boundaries in fitness/nutrition documents. Given a document outline and paragraph previews, determine where major topic shifts occur.

Respond with JSON: { "boundaries": ["Heading text 1", "Heading text 2", ...] }
Only include headings where a genuinely different topic begins (not every heading is a boundary).`,
      },
      {
        role: "user",
        content: `Document outline:\n${outline}\n\nParagraph previews:\n${paragraphPreview}`,
      },
    ],
  });

  const content = response.choices[0]?.message?.content ?? "{}";
  try {
    const parsed = JSON.parse(content) as { boundaries?: string[] };
    return parsed.boundaries ?? [];
  } catch {
    return [];
  }
}

/**
 * Re-split a low-coherence chunk at the suggested split point.
 * Falls back to sentence-boundary splitting if the split point isn't found.
 */
function resplitChunk(
  chunkText: string,
  suggestedSplitPoint?: string,
): string[] {
  if (suggestedSplitPoint) {
    const idx = chunkText.indexOf(suggestedSplitPoint);
    if (idx > 0) {
      const part1 = chunkText.slice(0, idx).trim();
      const part2 = chunkText.slice(idx).trim();
      if (part1 && part2) return [part1, part2];
    }
  }

  // Fallback: split at the midpoint sentence boundary.
  const sentences = splitIntoSentences(chunkText);
  if (sentences.length < 2) return [chunkText];

  const mid = Math.floor(sentences.length / 2);
  const part1 = sentences.slice(0, mid).join(" ").trim();
  const part2 = sentences.slice(mid).join(" ").trim();
  return [part1, part2].filter(Boolean);
}

/**
 * Merge adjacent chunks that are below the minimum token threshold.
 */
function mergeSmallChunks(
  chunks: { text: string; startOffset: number }[],
  minTokens: number,
): { text: string; startOffset: number }[] {
  if (chunks.length === 0) return [];
  const merged: { text: string; startOffset: number }[] = [];
  let buffer = chunks[0];

  for (let i = 1; i < chunks.length; i++) {
    const bufferTokens = countTokens(buffer.text);
    if (bufferTokens < minTokens) {
      // Merge with next chunk.
      buffer = {
        text: buffer.text + "\n\n" + chunks[i].text,
        startOffset: buffer.startOffset,
      };
    } else {
      merged.push(buffer);
      buffer = chunks[i];
    }
  }
  merged.push(buffer);

  return merged;
}

// ---------------------------------------------------------------------------
// Main chunking pipeline
// ---------------------------------------------------------------------------

/**
 * Run the full chunking pipeline on a markdown document.
 *
 * 1. Apply sliding window chunking.
 * 2. Merge chunks that are too small.
 * 3. (Optional) Score coherence with LLM and re-split low scorers.
 * 4. Build metadata for each chunk.
 *
 * @param markdown - Full markdown document text.
 * @param filename - Source filename (e.g. "01_exercise_science.md").
 * @param config - Chunking configuration (partial — merged with defaults).
 * @param openaiClient - Optional OpenAI client (required if useLlmChunking is true).
 * @returns Array of fully-annotated Chunk objects.
 */
export async function chunkDocument(
  markdown: string,
  filename: string,
  config: Partial<ChunkerConfig> = {},
  openaiClient?: OpenAI,
): Promise<Chunk[]> {
  const cfg: ChunkerConfig = { ...DEFAULT_CONFIG, ...config };
  const sourceFile = filename.replace(/\.md$/, "");
  const category = categoryFromFilename(filename);

  // Step 1: Sliding window chunking.
  let rawChunks = slidingWindowChunk(markdown, cfg.windowSize, cfg.overlap);

  // Step 2: Merge tiny chunks.
  rawChunks = mergeSmallChunks(rawChunks, cfg.minChunkTokens);

  // Step 3: Optional LLM refinement pass.
  if (cfg.useLlmChunking && openaiClient) {
    // 3a: Identify semantic boundaries in the document (used for context).
    const _boundaries = await identifySemanticBoundaries(markdown, openaiClient, cfg.llmModel);

    // 3b: Score coherence of each chunk.
    const scores = await scoreChunkCoherence(
      rawChunks.map((c) => c.text),
      openaiClient,
      cfg.llmModel,
    );

    // 3c: Re-split chunks below coherence threshold.
    const refined: { text: string; startOffset: number }[] = [];
    for (let i = 0; i < rawChunks.length; i++) {
      const score = scores.find((s) => s.chunkIndex === i);
      if (score && score.score < cfg.coherenceThreshold) {
        const parts = resplitChunk(rawChunks[i].text, score.suggestedSplitPoint);
        let offset = rawChunks[i].startOffset;
        for (const part of parts) {
          refined.push({ text: part, startOffset: offset });
          offset += part.length + 2;
        }
      } else {
        refined.push(rawChunks[i]);
      }
    }

    // 3d: Merge runts created by re-splitting.
    rawChunks = mergeSmallChunks(refined, cfg.minChunkTokens);
  }

  // Step 4: Build annotated Chunk objects with metadata.
  const totalChunks = rawChunks.length;
  const chunks: Chunk[] = rawChunks.map((rc, index) => {
    const tokenCount = countTokens(rc.text);
    const metadata = buildChunkMetadata(
      rc.text,
      markdown,
      rc.startOffset,
      sourceFile,
      category,
      index,
      totalChunks,
      tokenCount,
    );
    return {
      id: makeChunkId(sourceFile, index),
      text: rc.text,
      tokenCount,
      metadata,
    };
  });

  return chunks;
}
