/**
 * Pinecone vector store client.
 * Handles index creation, batch upserts, querying, and namespace management.
 */

import { Pinecone, type Index, type RecordMetadata } from "@pinecone-database/pinecone";
import { withRetry, printProgress } from "./utils.js";
import type { EmbeddedChunk } from "./embedder.js";
import type { ChunkMetadata } from "./metadata-extractor.js";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Configuration for the Pinecone store. */
export interface PineconeStoreConfig {
  /** Pinecone API key. */
  apiKey: string;
  /** Pinecone index name. */
  indexName: string;
  /** Optional index host (for serverless/starter). */
  indexHost?: string;
  /** Namespace for vectors. Default "fitness-knowledge". */
  namespace: string;
  /** Number of vectors per upsert batch. Default 100. */
  batchSize: number;
  /** Embedding dimensions (must match index). */
  dimensions: number;
  /** Similarity metric. Default "cosine". */
  metric: "cosine" | "euclidean" | "dotproduct";
}

const DEFAULT_CONFIG: Partial<PineconeStoreConfig> = {
  namespace: "fitness-knowledge",
  batchSize: 100,
  dimensions: 1536,
  metric: "cosine",
};

/** Query result returned from similarity search. */
export interface QueryResult {
  id: string;
  score: number;
  metadata: ChunkMetadata;
  text?: string;
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

/**
 * Wrapper around the Pinecone SDK for the fitness knowledge base.
 * Provides batch upsert, query, delete, and index management.
 */
export class PineconeStore {
  private client: Pinecone;
  private index: Index<RecordMetadata> | null = null;
  private config: PineconeStoreConfig;

  constructor(config: Partial<PineconeStoreConfig> & { apiKey: string; indexName: string }) {
    this.config = { ...DEFAULT_CONFIG, ...config } as PineconeStoreConfig;
    this.client = new Pinecone({ apiKey: this.config.apiKey });
  }

  /**
   * Get or initialise the Pinecone index handle.
   * @returns The Pinecone Index object.
   */
  private getIndex(): Index<RecordMetadata> {
    if (!this.index) {
      if (this.config.indexHost) {
        this.index = this.client.index(this.config.indexName, this.config.indexHost);
      } else {
        this.index = this.client.index(this.config.indexName);
      }
    }
    return this.index;
  }

  // -----------------------------------------------------------------------
  // Index management
  // -----------------------------------------------------------------------

  /**
   * Create the Pinecone index if it does not already exist.
   * Uses the serverless spec for free-tier compatibility.
   * @returns True if a new index was created, false if it already existed.
   */
  async createIndexIfNotExists(): Promise<boolean> {
    const existing = await this.client.listIndexes();
    const names = existing.indexes?.map((i) => i.name) ?? [];

    if (names.includes(this.config.indexName)) {
      return false;
    }

    await this.client.createIndex({
      name: this.config.indexName,
      dimension: this.config.dimensions,
      metric: this.config.metric,
      spec: {
        serverless: {
          cloud: "aws",
          region: "us-east-1",
        },
      },
    });

    // Wait for the index to be ready.
    let ready = false;
    for (let i = 0; i < 60; i++) {
      const desc = await this.client.describeIndex(this.config.indexName);
      if (desc.status?.ready) {
        ready = true;
        break;
      }
      await new Promise((r) => setTimeout(r, 2000));
    }

    if (!ready) {
      throw new Error(`Index "${this.config.indexName}" did not become ready within 120 seconds.`);
    }

    return true;
  }

  /**
   * Describe the current index and return its configuration.
   * @returns Index description object from Pinecone.
   */
  async describeIndex() {
    return this.client.describeIndex(this.config.indexName);
  }

  /**
   * Get index statistics (vector count, dimensions, etc.).
   * @returns Stats object from Pinecone.
   */
  async getStats() {
    const index = this.getIndex();
    return index.describeIndexStats();
  }

  // -----------------------------------------------------------------------
  // Upsert
  // -----------------------------------------------------------------------

  /**
   * Upsert embedded chunks into Pinecone in batches.
   *
   * Each vector includes the chunk text in metadata under the "text" key
   * so it can be retrieved alongside the vector for display purposes.
   *
   * @param embeddedChunks - Array of chunks with their embeddings.
   * @param onProgress - Optional progress callback (current, total).
   * @returns Total number of vectors upserted.
   */
  async upsertChunks(
    embeddedChunks: EmbeddedChunk[],
    onProgress?: (current: number, total: number) => void,
  ): Promise<number> {
    const index = this.getIndex();
    const ns = index.namespace(this.config.namespace);
    const total = embeddedChunks.length;
    let upserted = 0;

    for (let i = 0; i < total; i += this.config.batchSize) {
      const batch = embeddedChunks.slice(i, i + this.config.batchSize);

      const vectors = batch.map((ec) => ({
        id: ec.chunk.id,
        values: ec.embedding,
        metadata: {
          text: ec.chunk.text,
          source_file: ec.chunk.metadata.source_file,
          category: ec.chunk.metadata.category,
          section: ec.chunk.metadata.section,
          subsection: ec.chunk.metadata.subsection ?? "",
          chunk_index: ec.chunk.metadata.chunk_index,
          total_chunks: ec.chunk.metadata.total_chunks,
          token_count: ec.chunk.metadata.token_count,
          has_numbers: ec.chunk.metadata.has_numbers,
          muscle_groups: ec.chunk.metadata.muscle_groups,
          exercise_names: ec.chunk.metadata.exercise_names,
          difficulty_tags: ec.chunk.metadata.difficulty_tags,
          topic_tags: ec.chunk.metadata.topic_tags,
        },
      }));

      await withRetry(async () => {
        await ns.upsert(vectors);
      });

      upserted += batch.length;
      onProgress?.(upserted, total);
    }

    return upserted;
  }

  // -----------------------------------------------------------------------
  // Query
  // -----------------------------------------------------------------------

  /**
   * Query the index by vector similarity with optional metadata filters.
   *
   * @param vector - Query embedding vector.
   * @param topK - Number of results to return. Default 10.
   * @param filter - Optional Pinecone metadata filter object.
   * @returns Array of QueryResult objects sorted by descending score.
   */
  async query(
    vector: number[],
    topK = 10,
    filter?: Record<string, unknown>,
  ): Promise<QueryResult[]> {
    const index = this.getIndex();
    const ns = index.namespace(this.config.namespace);

    const response = await withRetry(async () => {
      return ns.query({
        vector,
        topK,
        includeMetadata: true,
        filter,
      });
    });

    return (response.matches ?? []).map((match) => {
      const meta = (match.metadata ?? {}) as Record<string, unknown>;
      return {
        id: match.id,
        score: match.score ?? 0,
        text: meta.text as string | undefined,
        metadata: {
          source_file: (meta.source_file as string) ?? "",
          category: (meta.category as string) ?? "",
          section: (meta.section as string) ?? "",
          subsection: (meta.subsection as string) || undefined,
          chunk_index: (meta.chunk_index as number) ?? 0,
          total_chunks: (meta.total_chunks as number) ?? 0,
          token_count: (meta.token_count as number) ?? 0,
          has_numbers: (meta.has_numbers as boolean) ?? false,
          muscle_groups: (meta.muscle_groups as string[]) ?? [],
          exercise_names: (meta.exercise_names as string[]) ?? [],
          difficulty_tags: (meta.difficulty_tags as string[]) ?? [],
          topic_tags: (meta.topic_tags as string[]) ?? [],
        },
      };
    });
  }

  // -----------------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------------

  /**
   * Delete all vectors in the configured namespace.
   * Useful for full re-ingestion.
   */
  async deleteNamespace(): Promise<void> {
    const index = this.getIndex();
    const ns = index.namespace(this.config.namespace);
    await withRetry(async () => {
      await ns.deleteAll();
    });
  }

  /**
   * Delete vectors by ID prefix (e.g. all chunks from a specific file).
   * @param idPrefix - The prefix to match (e.g. "01_exercise_science").
   */
  async deleteByPrefix(idPrefix: string): Promise<void> {
    const index = this.getIndex();
    const ns = index.namespace(this.config.namespace);

    // Pinecone serverless supports deleteMany with filter, but for
    // starter plans we list then delete by IDs.
    // Use a query with a zero vector to list IDs — but this is unreliable.
    // Instead, use the list endpoint if available, or delete by known IDs.
    // For simplicity, we fetch by metadata filter on source_file.
    const zeroVector = new Array(this.config.dimensions).fill(0);
    const results = await ns.query({
      vector: zeroVector,
      topK: 10000,
      filter: { source_file: { $eq: idPrefix.replace(/\.md$/, "") } },
      includeMetadata: false,
    });

    const ids = (results.matches ?? []).map((m) => m.id);
    if (ids.length > 0) {
      // Delete in batches of 1000.
      for (let i = 0; i < ids.length; i += 1000) {
        const batch = ids.slice(i, i + 1000);
        await withRetry(async () => {
          await ns.deleteMany(batch);
        });
      }
    }
  }

  /** Get the configured namespace. */
  get namespace(): string {
    return this.config.namespace;
  }

  /** Get the configured index name. */
  get indexName(): string {
    return this.config.indexName;
  }
}
