import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for the RAG (Retrieval-Augmented Generation) pipeline.
///
/// Reads Pinecone and embedding settings from `.env`. When [isConfigured]
/// returns `false` the app falls back to context-only AI prompting — no
/// retrieval step is performed.
abstract final class RagConfig {
  // ──────────────────────── Pinecone ──────────────────────────────────────

  static String get pineconeApiKey => dotenv.env['PINECONE_API_KEY'] ?? '';

  static String get pineconeIndexHost =>
      dotenv.env['PINECONE_INDEX_HOST'] ?? '';

  static String get pineconeIndexName =>
      dotenv.env['PINECONE_INDEX_NAME'] ?? 'alfanutrition-rag';

  // ──────────────────────── Embeddings ────────────────────────────────────

  static String get embeddingModel =>
      dotenv.env['OPENAI_EMBEDDING_MODEL'] ?? 'text-embedding-3-small';

  static int get embeddingDimensions =>
      int.tryParse(dotenv.env['OPENAI_EMBEDDING_DIMENSIONS'] ?? '') ?? 1536;

  // ──────────────────────── Retrieval defaults ────────────────────────────

  /// Default Pinecone namespace for fitness knowledge.
  static const String namespace = 'fitness-knowledge';

  /// Number of vectors to request from Pinecone before re-ranking.
  static const int defaultTopK = 8;

  /// Minimum cosine similarity score to keep a retrieved chunk.
  static const double minRelevanceScore = 0.7;

  /// Maximum number of chunks kept after re-ranking.
  static const int maxChunksAfterRerank = 5;

  // ──────────────────────── Guards ────────────────────────────────────────

  /// `true` when both the Pinecone API key and index host are present.
  static bool get isConfigured =>
      pineconeApiKey.isNotEmpty && pineconeIndexHost.isNotEmpty;
}
