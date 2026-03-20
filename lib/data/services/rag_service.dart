import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:alfanutrition/data/services/ai_service.dart';
import 'package:alfanutrition/data/services/rag_config.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// High-level intent detected from a user query.
enum QueryIntent {
  exercise,
  nutrition,
  anatomy,
  training,
  diet,
  recovery,
  supplements,
  general,
  noRetrieval,
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

/// Result of classifying a user query before retrieval.
class QueryClassification {
  final QueryIntent primaryIntent;
  final List<QueryIntent> secondaryIntents;
  final bool needsRetrieval;
  final List<String> suggestedNamespaces;
  final Map<String, dynamic>? metadataFilters;

  const QueryClassification({
    required this.primaryIntent,
    this.secondaryIntents = const [],
    required this.needsRetrieval,
    this.suggestedNamespaces = const [],
    this.metadataFilters,
  });
}

/// A single chunk retrieved from the Pinecone vector store.
class RetrievedChunk {
  final String id;
  final String content;
  final double score;
  final Map<String, dynamic> metadata;

  const RetrievedChunk({
    required this.id,
    required this.content,
    required this.score,
    this.metadata = const {},
  });
}

/// Aggregated user context pulled from Supabase for prompt augmentation.
class UserRagContext {
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> recentWorkouts;
  final List<Map<String, dynamic>> recentMeals;
  final Map<String, dynamic>? latestMetrics;
  final Map<String, dynamic>? weeklyVolume;

  const UserRagContext({
    this.profile,
    this.recentWorkouts = const [],
    this.recentMeals = const [],
    this.latestMetrics,
    this.weeklyVolume,
  });
}

/// The full output of the RAG pipeline.
class RagResult {
  final List<RetrievedChunk> chunks;
  final UserRagContext userContext;
  final QueryClassification classification;
  final String augmentedSystemPrompt;
  final int totalTokensUsed;

  const RagResult({
    required this.chunks,
    required this.userContext,
    required this.classification,
    required this.augmentedSystemPrompt,
    this.totalTokensUsed = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyword maps for classification
// ─────────────────────────────────────────────────────────────────────────────

const _exerciseKeywords = <String>{
  'exercise', 'bench', 'squat', 'deadlift', 'press', 'curl', 'row',
  'pullup', 'pull-up', 'pushup', 'push-up', 'lunge', 'fly', 'flye',
  'raise', 'extension', 'dip', 'shrug', 'crunch', 'plank', 'hip thrust',
  'rdl', 'leg press', 'cable', 'dumbbell', 'barbell', 'machine',
  'kettlebell', 'form', 'technique', 'variation', 'alternative',
};

const _nutritionKeywords = <String>{
  'calorie', 'calories', 'kcal', 'macro', 'macros', 'protein', 'carb',
  'carbs', 'carbohydrate', 'fat', 'fats', 'fiber', 'fibre', 'nutrition',
  'eat', 'eating', 'food', 'meal', 'snack', 'breakfast', 'lunch', 'dinner',
  'pre-workout', 'post-workout', 'nutrient', 'vitamin', 'mineral',
};

const _anatomyKeywords = <String>{
  'muscle', 'muscles', 'anatomy', 'chest', 'back', 'shoulder', 'shoulders',
  'bicep', 'biceps', 'tricep', 'triceps', 'quad', 'quads', 'quadriceps',
  'hamstring', 'hamstrings', 'glute', 'glutes', 'calf', 'calves', 'core',
  'abs', 'abdominal', 'forearm', 'forearms', 'lat', 'lats', 'trap', 'traps',
  'deltoid', 'pec', 'pecs', 'muscle group',
};

const _trainingKeywords = <String>{
  'program', 'programming', 'split', 'routine', 'plan', 'workout plan',
  'progressive overload', 'periodization', 'volume', 'intensity', 'frequency',
  'sets', 'reps', 'rep range', 'hypertrophy', 'strength', 'power',
  'endurance', 'deload', 'plateau', 'one rep max', '1rm', 'training',
  'superset', 'dropset', 'rest pause', 'tempo',
};

const _dietKeywords = <String>{
  'diet', 'dieting', 'cut', 'cutting', 'bulk', 'bulking', 'lean bulk',
  'recomp', 'recomposition', 'deficit', 'surplus', 'maintenance',
  'intermittent fasting', 'keto', 'paleo', 'vegan', 'vegetarian',
  'meal plan', 'meal prep', 'weight loss', 'fat loss', 'gain weight',
};

const _recoveryKeywords = <String>{
  'recovery', 'rest', 'sleep', 'overtraining', 'soreness', 'doms',
  'stretch', 'stretching', 'mobility', 'foam roll', 'warm up', 'cool down',
  'injury', 'pain', 'prevention', 'fatigue', 'burnout',
};

const _supplementKeywords = <String>{
  'supplement', 'supplements', 'creatine', 'whey', 'protein powder',
  'bcaa', 'eaa', 'pre workout', 'caffeine', 'beta alanine', 'citrulline',
  'omega', 'fish oil', 'multivitamin', 'vitamin d', 'zinc', 'magnesium',
};

const _noRetrievalPatterns = <String>[
  'hello', 'hi', 'hey', 'thanks', 'thank you', 'bye', 'goodbye',
  'good morning', 'good afternoon', 'good evening', 'how are you',
  'what can you do', 'who are you', 'ok', 'okay', 'sure', 'yes', 'no',
  'great', 'awesome', 'cool', 'nice', 'got it',
];

/// Maps each intent to the Pinecone namespaces that should be searched.
const _intentNamespaceMap = <QueryIntent, List<String>>{
  QueryIntent.exercise: ['exercise_guides', 'exercise_science'],
  QueryIntent.nutrition: ['nutrition', 'diet'],
  QueryIntent.anatomy: ['muscle_anatomy'],
  QueryIntent.training: ['exercise_science', 'exercise_guides'],
  QueryIntent.diet: ['diet', 'nutrition'],
  QueryIntent.recovery: ['exercise_science', 'nutrition'],
  QueryIntent.supplements: ['nutrition', 'diet'],
  QueryIntent.general: [RagConfig.namespace],
};

// ─────────────────────────────────────────────────────────────────────────────
// RagService
// ─────────────────────────────────────────────────────────────────────────────

/// Agentic RAG orchestrator for the AlfaNutrition AI coach.
///
/// Pipeline: classify -> decompose -> embed -> search -> rerank -> augment.
///
/// This service is completely optional. When Pinecone is not configured the
/// app falls back to context-only prompting with zero performance cost.
class RagService {
  static const _openAiBaseUrl = 'https://api.openai.com/v1';

  String get _openAiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Map<String, String> get _openAiHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAiKey',
      };

  Map<String, String> get _pineconeHeaders => {
        'Content-Type': 'application/json',
        'Api-Key': RagConfig.pineconeApiKey,
      };

  // ─────────────────── Step 1: Query classification ────────────────────────

  /// Classify the user query into one or more intents using fast keyword
  /// matching. No LLM call is required.
  QueryClassification classifyQuery(String query, AiAgentType agent) {
    final lower = query.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));

    // Check for trivial / no-retrieval messages first.
    for (final pattern in _noRetrievalPatterns) {
      if (lower == pattern || lower == '$pattern.' || lower == '$pattern!') {
        return const QueryClassification(
          primaryIntent: QueryIntent.noRetrieval,
          needsRetrieval: false,
        );
      }
    }

    // Very short messages (1-2 words, not fitness terms) skip retrieval.
    if (words.length <= 2 && !_containsAny(lower, _exerciseKeywords) &&
        !_containsAny(lower, _nutritionKeywords) &&
        !_containsAny(lower, _anatomyKeywords)) {
      return const QueryClassification(
        primaryIntent: QueryIntent.noRetrieval,
        needsRetrieval: false,
      );
    }

    // Score each intent category.
    final scores = <QueryIntent, int>{
      QueryIntent.exercise: _scoreKeywords(lower, _exerciseKeywords),
      QueryIntent.nutrition: _scoreKeywords(lower, _nutritionKeywords),
      QueryIntent.anatomy: _scoreKeywords(lower, _anatomyKeywords),
      QueryIntent.training: _scoreKeywords(lower, _trainingKeywords),
      QueryIntent.diet: _scoreKeywords(lower, _dietKeywords),
      QueryIntent.recovery: _scoreKeywords(lower, _recoveryKeywords),
      QueryIntent.supplements: _scoreKeywords(lower, _supplementKeywords),
    };

    // Sort by score descending.
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // If no keywords matched, use agent type as a soft signal.
    if (sorted.first.value == 0) {
      final fallback = agent == AiAgentType.trainer
          ? QueryIntent.training
          : agent == AiAgentType.nutritionist
              ? QueryIntent.nutrition
              : QueryIntent.general;
      final ns = _intentNamespaceMap[fallback] ?? [RagConfig.namespace];
      return QueryClassification(
        primaryIntent: fallback,
        needsRetrieval: true,
        suggestedNamespaces: ns,
      );
    }

    final primary = sorted.first.key;
    final secondary = sorted
        .skip(1)
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    // Collect namespaces from primary + secondary intents (deduplicated).
    final namespaces = <String>{
      ...(_intentNamespaceMap[primary] ?? [RagConfig.namespace]),
      for (final s in secondary)
        ...(_intentNamespaceMap[s] ?? []),
    }.toList();

    return QueryClassification(
      primaryIntent: primary,
      secondaryIntents: secondary,
      needsRetrieval: true,
      suggestedNamespaces: namespaces,
    );
  }

  // ─────────────────── Step 2: Query decomposition ─────────────────────────

  /// Break a complex multi-topic question into 2-3 focused sub-queries.
  ///
  /// Only called when the classification detects multiple intents.
  /// Simple single-intent queries return the original query unchanged.
  Future<List<String>> decomposeQuery(String query) async {
    // Only decompose if the query is long enough to be multi-topic.
    if (query.split(RegExp(r'\s+')).length < 8) {
      return [query];
    }

    try {
      final body = jsonEncode({
        'model': dotenv.env['OPENAI_MODEL'] ?? 'gpt-5.4-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You decompose fitness questions into 2-3 specific search '
                'queries for a vector database. Return ONLY a JSON array of '
                'strings, nothing else. Each query should be concise (5-10 '
                'words) and target one specific topic.',
          },
          {
            'role': 'user',
            'content': query,
          },
        ],
        'temperature': 0.3,
        'max_completion_tokens': 200,
      });

      final response = await http.post(
        Uri.parse('$_openAiBaseUrl/chat/completions'),
        headers: _openAiHeaders,
        body: body,
      );

      if (response.statusCode != 200) {
        debugPrint('RAG decompose failed: ${response.statusCode}');
        return [query];
      }

      final data = jsonDecode(response.body);
      final content =
          data['choices'][0]['message']['content'] as String? ?? '';

      // Parse the JSON array from the response.
      final match = RegExp(r'\[[\s\S]*?\]').firstMatch(content);
      if (match != null) {
        final list = jsonDecode(match.group(0)!) as List;
        final queries = list.map((e) => e.toString()).toList();
        if (queries.isNotEmpty && queries.length <= 4) {
          return queries;
        }
      }
    } catch (e) {
      debugPrint('RAG query decomposition error: $e');
    }

    return [query];
  }

  // ─────────────────── Step 3: Generate embeddings ─────────────────────────

  /// Generate an embedding vector for [text] via the OpenAI embeddings API.
  Future<List<double>> embedText(String text) async {
    final body = jsonEncode({
      'model': RagConfig.embeddingModel,
      'input': text,
      'dimensions': RagConfig.embeddingDimensions,
    });

    final response = await http.post(
      Uri.parse('$_openAiBaseUrl/embeddings'),
      headers: _openAiHeaders,
      body: body,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      final msg = error['error']?['message'] ?? 'Unknown embedding error';
      throw Exception('Embedding API error (${response.statusCode}): $msg');
    }

    final data = jsonDecode(response.body);
    final embedding = data['data'][0]['embedding'] as List;
    return embedding.map((e) => (e as num).toDouble()).toList();
  }

  // ─────────────────── Step 4: Search Pinecone ─────────────────────────────

  /// Query the Pinecone index for vectors similar to [embedding].
  Future<List<RetrievedChunk>> searchPinecone({
    required List<double> embedding,
    int topK = 8,
    String namespace = 'fitness-knowledge',
    Map<String, dynamic>? filter,
    double minScore = 0.7,
  }) async {
    final host = RagConfig.pineconeIndexHost;
    if (host.isEmpty) return [];

    final body = <String, dynamic>{
      'vector': embedding,
      'topK': topK,
      'includeMetadata': true,
      'namespace': namespace,
    };
    if (filter != null && filter.isNotEmpty) {
      body['filter'] = filter;
    }

    final uri = host.startsWith('http')
        ? Uri.parse('$host/query')
        : Uri.parse('https://$host/query');

    final response = await http.post(
      uri,
      headers: _pineconeHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Pinecone search failed (${response.statusCode}): ${response.body}',
      );
      return [];
    }

    final data = jsonDecode(response.body);
    final matches = data['matches'] as List? ?? [];

    final chunks = <RetrievedChunk>[];
    for (final match in matches) {
      final score = (match['score'] as num?)?.toDouble() ?? 0.0;
      if (score < minScore) continue;

      final metadata =
          Map<String, dynamic>.from(match['metadata'] as Map? ?? {});
      final content = metadata['text'] as String? ??
          metadata['content'] as String? ??
          '';

      if (content.isEmpty) continue;

      chunks.add(RetrievedChunk(
        id: match['id'] as String? ?? '',
        content: content,
        score: score,
        metadata: metadata,
      ));
    }

    return chunks;
  }

  // ─────────────────── Step 5: Re-rank chunks ──────────────────────────────

  /// Lightweight client-side re-ranking using keyword overlap and metadata
  /// heuristics. Returns the top [RagConfig.maxChunksAfterRerank] chunks.
  List<RetrievedChunk> rerankChunks(
    List<RetrievedChunk> chunks,
    String query,
  ) {
    if (chunks.isEmpty) return [];

    final queryWords = _tokenize(query);
    final scored = <_ScoredChunk>[];

    for (final chunk in chunks) {
      var adjustedScore = chunk.score;

      // Keyword overlap boost (TF-IDF style).
      final chunkWords = _tokenize(chunk.content);
      final overlap = queryWords.where(chunkWords.contains).length;
      final overlapRatio =
          queryWords.isEmpty ? 0.0 : overlap / queryWords.length;
      adjustedScore += overlapRatio * 0.15;

      // Boost chunks that mention specific muscles / exercises from query.
      for (final word in queryWords) {
        if (_exerciseKeywords.contains(word) ||
            _anatomyKeywords.contains(word)) {
          if (chunk.content.toLowerCase().contains(word)) {
            adjustedScore += 0.05;
          }
        }
      }

      // Boost chunks with numbers when the query asks for recommendations.
      final asksForNumbers = query.toLowerCase().contains('how many') ||
          query.toLowerCase().contains('how much') ||
          query.toLowerCase().contains('recommend') ||
          query.toLowerCase().contains('optimal') ||
          query.toLowerCase().contains('best');
      if (asksForNumbers &&
          (chunk.metadata['has_numbers'] == true ||
              RegExp(r'\d').hasMatch(chunk.content))) {
        adjustedScore += 0.05;
      }

      scored.add(_ScoredChunk(chunk, adjustedScore));
    }

    // Sort by adjusted score descending.
    scored.sort((a, b) => b.adjustedScore.compareTo(a.adjustedScore));

    // Deduplicate: penalize chunks that overlap heavily with higher-ranked
    // ones already in the result list.
    final selected = <_ScoredChunk>[];
    for (final candidate in scored) {
      if (selected.length >= RagConfig.maxChunksAfterRerank) break;

      final isDuplicate = selected.any((s) {
        return _jaccardSimilarity(
              _tokenize(s.chunk.content),
              _tokenize(candidate.chunk.content),
            ) >
            0.6;
      });
      if (!isDuplicate) {
        selected.add(candidate);
      }
    }

    return selected.map((s) => RetrievedChunk(
      id: s.chunk.id,
      content: s.chunk.content,
      score: s.adjustedScore,
      metadata: s.chunk.metadata,
    )).toList();
  }

  // ─────────────────── Step 6: User context from Supabase ──────────────────

  /// Pull the user's profile, recent activity, and metrics from Supabase.
  ///
  /// Returns an empty [UserRagContext] when Supabase is not connected.
  Future<UserRagContext> getUserContext(Ref ref) async {
    final source = ref.read(dataSourceProvider);
    if (source != DataSourceType.supabase) {
      return const UserRagContext();
    }

    try {
      // Run all queries in parallel.
      final results = await Future.wait([
        _fetchProfile(ref),
        _fetchRecentWorkouts(ref),
        _fetchTodaysMeals(ref),
        _fetchLatestMetrics(ref),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final workouts = results[1] as List<Map<String, dynamic>>;
      final meals = results[2] as List<Map<String, dynamic>>;
      final metrics = results[3] as Map<String, dynamic>?;

      // Compute weekly volume from recent workouts.
      final weeklyVolume = _computeWeeklyVolume(workouts);

      return UserRagContext(
        profile: profile,
        recentWorkouts: workouts,
        recentMeals: meals,
        latestMetrics: metrics,
        weeklyVolume: weeklyVolume,
      );
    } catch (e) {
      debugPrint('RAG user context error: $e');
      return const UserRagContext();
    }
  }

  Future<Map<String, dynamic>?> _fetchProfile(Ref ref) async {
    try {
      final repo = ref.read(sbProfileRepositoryProvider);
      final profile = await repo.getProfile();
      if (profile == null) return null;
      return {
        'name': profile.name,
        'weight': profile.weight,
        'height': profile.height,
        'age': profile.computedAge,
        'goal': profile.goal.name,
        'level': profile.level.name,
        'dailyCalorieTarget': profile.dailyCalorieTarget,
        'proteinTarget': profile.proteinTarget,
        'carbsTarget': profile.carbsTarget,
        'fatsTarget': profile.fatsTarget,
        'workoutDaysPerWeek': profile.workoutDaysPerWeek,
        'gender': profile.gender?.name,
      };
    } catch (e) {
      debugPrint('RAG fetch profile error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentWorkouts(Ref ref) async {
    try {
      final repo = ref.read(sbWorkoutRepositoryProvider);
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final workouts = await repo.getWorkouts(from: weekAgo, to: now);
      final recent = workouts.take(5).toList();
      return recent.map((w) {
        return {
          'name': w.name,
          'date': w.date.toIso8601String(),
          'duration_minutes': (w.durationSeconds / 60).round(),
          'exercise_count': w.exercises.length,
          'total_sets': w.exercises.fold<int>(
            0,
            (sum, e) => sum + e.sets.length,
          ),
          'muscles': w.exercises
              .map((e) => e.primaryMuscle.name)
              .toSet()
              .toList(),
        };
      }).toList();
    } catch (e) {
      debugPrint('RAG fetch workouts error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTodaysMeals(Ref ref) async {
    try {
      final repo = ref.read(sbNutritionRepositoryProvider);
      final meals = await repo.getMealsForDate(DateTime.now());
      return meals.map((m) {
        return {
          'name': m.name,
          'meal_type': m.mealType.name,
          'calories': m.calories,
          'protein': m.protein,
          'carbs': m.carbs,
          'fats': m.fats,
        };
      }).toList();
    } catch (e) {
      debugPrint('RAG fetch meals error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestMetrics(Ref ref) async {
    try {
      final repo = ref.read(sbBodyMetricRepositoryProvider);
      final metric = await repo.getLatestMetric();
      if (metric == null) return null;
      return {
        'weight': metric.weight,
        'body_fat_percentage': metric.bodyFatPercentage,
        'date': metric.date.toIso8601String(),
        'chest': metric.chest,
        'waist': metric.waist,
        'hips': metric.hips,
      };
    } catch (e) {
      debugPrint('RAG fetch metrics error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _computeWeeklyVolume(
    List<Map<String, dynamic>> workouts,
  ) {
    if (workouts.isEmpty) return null;

    final volume = <String, int>{};
    for (final w in workouts) {
      final muscles = w['muscles'] as List? ?? [];
      final totalSets = w['total_sets'] as int? ?? 0;
      final setsPerMuscle =
          muscles.isEmpty ? 0 : (totalSets / muscles.length).round();
      for (final m in muscles) {
        final key = m.toString();
        volume[key] = (volume[key] ?? 0) + setsPerMuscle;
      }
    }

    return volume;
  }

  // ─────────────────── Step 7: Build augmented prompt ──────────────────────

  /// Construct the final system prompt combining agent persona, retrieved
  /// knowledge, user context, and response guidelines.
  String buildAugmentedPrompt({
    required String userQuery,
    required List<RetrievedChunk> relevantChunks,
    required UserRagContext userContext,
    required AiAgentType agent,
    required List<AiMessage> history,
  }) {
    final buffer = StringBuffer();

    // Agent persona.
    buffer.writeln(agent.systemPromptHint);
    buffer.writeln();

    // User profile context.
    final p = userContext.profile;
    if (p != null && p.isNotEmpty) {
      buffer.writeln('USER PROFILE:');
      if (p['name'] != null) buffer.writeln('- Name: ${p['name']}');
      if (p['weight'] != null) buffer.writeln('- Weight: ${p['weight']}kg');
      if (p['height'] != null) buffer.writeln('- Height: ${p['height']}cm');
      if (p['age'] != null) buffer.writeln('- Age: ${p['age']}');
      if (p['gender'] != null) buffer.writeln('- Gender: ${p['gender']}');
      if (p['goal'] != null) buffer.writeln('- Goal: ${p['goal']}');
      if (p['level'] != null) buffer.writeln('- Experience: ${p['level']}');
      if (p['dailyCalorieTarget'] != null) {
        buffer.writeln('- Daily calorie target: ${p['dailyCalorieTarget']} kcal');
      }
      if (p['proteinTarget'] != null) {
        buffer.writeln('- Protein target: ${p['proteinTarget']}g');
      }
      if (p['carbsTarget'] != null) {
        buffer.writeln('- Carbs target: ${p['carbsTarget']}g');
      }
      if (p['fatsTarget'] != null) {
        buffer.writeln('- Fat target: ${p['fatsTarget']}g');
      }
      if (p['workoutDaysPerWeek'] != null) {
        buffer.writeln(
          '- Workout frequency: ${p['workoutDaysPerWeek']} days/week',
        );
      }
      buffer.writeln();
    }

    // Retrieved knowledge.
    if (relevantChunks.isNotEmpty) {
      buffer.writeln('--- BEGIN RELEVANT KNOWLEDGE ---');
      for (var i = 0; i < relevantChunks.length; i++) {
        final chunk = relevantChunks[i];
        final section =
            chunk.metadata['section'] as String? ??
            chunk.metadata['title'] as String? ??
            'Source ${i + 1}';
        final scoreStr = chunk.score.toStringAsFixed(2);
        buffer.writeln('[${i + 1}: $section | relevance: $scoreStr]');
        buffer.writeln(chunk.content);
        buffer.writeln();
      }
      buffer.writeln('--- END RELEVANT KNOWLEDGE ---');
      buffer.writeln();
    }

    // Recent activity.
    if (userContext.recentWorkouts.isNotEmpty) {
      buffer.writeln('RECENT WORKOUTS (last 7 days):');
      for (final w in userContext.recentWorkouts) {
        final muscles = (w['muscles'] as List?)?.join(', ') ?? 'unknown';
        buffer.writeln(
          '- ${w['name']} (${w['duration_minutes']}min, '
          '${w['exercise_count']} exercises, muscles: $muscles)',
        );
      }
      buffer.writeln();
    }

    if (userContext.recentMeals.isNotEmpty) {
      buffer.writeln("TODAY'S NUTRITION:");
      var totalCal = 0.0;
      var totalPro = 0.0;
      var totalCarb = 0.0;
      var totalFat = 0.0;
      for (final m in userContext.recentMeals) {
        totalCal += (m['calories'] as num?)?.toDouble() ?? 0;
        totalPro += (m['protein'] as num?)?.toDouble() ?? 0;
        totalCarb += (m['carbs'] as num?)?.toDouble() ?? 0;
        totalFat += (m['fats'] as num?)?.toDouble() ?? 0;
      }
      buffer.writeln(
        '- Consumed so far: ${totalCal.round()} kcal, '
        '${totalPro.round()}g protein, ${totalCarb.round()}g carbs, '
        '${totalFat.round()}g fat '
        '(${userContext.recentMeals.length} meals)',
      );
      buffer.writeln();
    }

    if (userContext.latestMetrics != null) {
      final m = userContext.latestMetrics!;
      buffer.writeln('LATEST BODY METRICS:');
      if (m['weight'] != null) buffer.writeln('- Weight: ${m['weight']}kg');
      if (m['body_fat_percentage'] != null) {
        buffer.writeln('- Body fat: ${m['body_fat_percentage']}%');
      }
      buffer.writeln();
    }

    if (userContext.weeklyVolume != null &&
        userContext.weeklyVolume!.isNotEmpty) {
      buffer.writeln('WEEKLY VOLUME (sets per muscle):');
      userContext.weeklyVolume!.forEach((muscle, sets) {
        buffer.writeln('- $muscle: $sets sets');
      });
      buffer.writeln();
    }

    // Database action instructions.
    buffer.writeln('DATABASE ACTIONS:');
    buffer.writeln(
      'When the user asks you to log, record, or track something, include a '
      'JSON action block in your response. The app will parse and execute it.',
    );
    buffer.writeln('Wrap actions in ```action``` code fences. Examples:');
    buffer.writeln();
    buffer.writeln('To log a meal:');
    buffer.writeln('```action');
    buffer.writeln(
      '{"type":"log_meal","label":"Log Chicken Breast","data":{"name":"Chicken '
      'Breast","calories":165,"protein":31,"carbs":0,"fats":3.6,"fiber":0,'
      '"meal_type":"lunch","serving_size":100,"serving_unit":"g"}}',
    );
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('To log a workout:');
    buffer.writeln('```action');
    buffer.writeln(
      '{"type":"log_workout","label":"Log Push Day","data":{"name":"Push Day",'
      '"duration_minutes":60,"exercises":[{"name":"Bench Press",'
      '"exercise_id":"barbell-bench-press","primary_muscle":"chest",'
      '"sets":[{"weight":80,"reps":5},{"weight":80,"reps":5},'
      '{"weight":80,"reps":5}]}]}}',
    );
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('To log body metrics:');
    buffer.writeln('```action');
    buffer.writeln(
      '{"type":"log_body_metric","label":"Log Weight","data":{"weight":80.5}}',
    );
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('To update weight only:');
    buffer.writeln('```action');
    buffer.writeln(
      '{"type":"update_weight","label":"Update Weight","data":{"weight":80.5}}',
    );
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln(
      'Supported action types: log_meal, log_workout, log_body_metric, '
      'update_weight, update_profile.',
    );
    buffer.writeln(
      'IMPORTANT: Only include action blocks when the user explicitly asks to '
      'log/record/track something. For advice-only questions, do NOT include '
      'actions.',
    );
    buffer.writeln(
      'Always include your conversational response text OUTSIDE the action '
      'block.',
    );
    buffer.writeln();

    // Response guidelines.
    buffer.writeln('RESPONSE GUIDELINES:');
    buffer.writeln('- Be concise and practical. No filler or pleasantries.');
    buffer.writeln('- Give specific, actionable advice with numbers.');
    buffer.writeln(
      "- Reference the user's data when relevant (weight, goals, targets).",
    );
    buffer.writeln('- Use metric units (kg, cm, kcal, grams).');
    buffer.writeln(
      '- Do not use markdown formatting (no **, ##, etc). Use plain text.',
    );
    if (relevantChunks.isNotEmpty) {
      buffer.writeln(
        '- Ground your answers in the RELEVANT KNOWLEDGE provided above. '
        'Cite specific data points when possible.',
      );
      buffer.writeln(
        '- If the knowledge does not cover the question, rely on your '
        'training but note that the advice is general.',
      );
    }
    buffer.writeln('- Keep responses under 250 words unless asked for detail.');
    buffer.writeln('- End with 1-2 brief follow-up questions or next steps.');

    return buffer.toString();
  }

  // ─────────────────── Full pipeline ───────────────────────────────────────

  /// Run the full RAG pipeline: classify, decompose, embed, search, rerank,
  /// and build the augmented system prompt.
  Future<RagResult> retrieve({
    required String query,
    required AiAgentType agent,
    required Ref ref,
  }) async {
    // Step 1: Classify
    final classification = classifyQuery(query, agent);
    if (!classification.needsRetrieval) {
      final userCtx = await getUserContext(ref);
      return RagResult(
        chunks: [],
        userContext: userCtx,
        classification: classification,
        augmentedSystemPrompt: buildAugmentedPrompt(
          userQuery: query,
          relevantChunks: [],
          userContext: userCtx,
          agent: agent,
          history: [],
        ),
      );
    }

    // Step 2 & 6 run in parallel: decompose + fetch user context.
    final hasMultipleIntents = classification.secondaryIntents.isNotEmpty &&
        query.split(RegExp(r'\s+')).length >= 8;

    final futures = await Future.wait([
      hasMultipleIntents ? decomposeQuery(query) : Future.value([query]),
      getUserContext(ref),
    ]);

    final subQueries = futures[0] as List<String>;
    final userContext = futures[1] as UserRagContext;

    // Step 3 & 4: Embed each sub-query and search Pinecone in parallel.
    var tokenEstimate = 0;
    final allChunks = <RetrievedChunk>[];

    final searchFutures = <Future<List<RetrievedChunk>>>[];
    for (final subQuery in subQueries) {
      searchFutures.add(_embedAndSearch(
        subQuery,
        classification.suggestedNamespaces,
        classification.metadataFilters,
      ));
    }

    final searchResults = await Future.wait(searchFutures);
    for (final chunks in searchResults) {
      allChunks.addAll(chunks);
    }

    // Estimate tokens: ~1 token per 4 characters for retrieved content.
    for (final chunk in allChunks) {
      tokenEstimate += (chunk.content.length / 4).ceil();
    }

    // Step 5: Re-rank.
    final reranked = rerankChunks(allChunks, query);

    // Step 7: Build augmented prompt.
    final prompt = buildAugmentedPrompt(
      userQuery: query,
      relevantChunks: reranked,
      userContext: userContext,
      agent: agent,
      history: [],
    );

    // Estimate total prompt tokens.
    tokenEstimate += (prompt.length / 4).ceil();

    return RagResult(
      chunks: reranked,
      userContext: userContext,
      classification: classification,
      augmentedSystemPrompt: prompt,
      totalTokensUsed: tokenEstimate,
    );
  }

  /// Embed a single query and search across multiple namespaces.
  Future<List<RetrievedChunk>> _embedAndSearch(
    String query,
    List<String> namespaces,
    Map<String, dynamic>? filters,
  ) async {
    try {
      final embedding = await embedText(query);
      final results = <RetrievedChunk>[];

      // Search each namespace in parallel.
      final namespacesToSearch =
          namespaces.isEmpty ? [RagConfig.namespace] : namespaces;

      final futures = namespacesToSearch.map((ns) {
        return searchPinecone(
          embedding: embedding,
          topK: RagConfig.defaultTopK,
          namespace: ns,
          filter: filters,
          minScore: RagConfig.minRelevanceScore,
        );
      });

      final searchResults = await Future.wait(futures);
      for (final chunks in searchResults) {
        results.addAll(chunks);
      }

      return results;
    } catch (e) {
      debugPrint('RAG embed+search error: $e');
      return [];
    }
  }

  // ─────────────────── Private helpers ─────────────────────────────────────

  /// Count how many keywords from [keywords] appear in [text].
  static int _scoreKeywords(String text, Set<String> keywords) {
    var score = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) score++;
    }
    return score;
  }

  /// Whether [text] contains any word from [keywords].
  static bool _containsAny(String text, Set<String> keywords) {
    return keywords.any(text.contains);
  }

  /// Tokenize text into a set of lowercased words, removing stop words.
  static Set<String> _tokenize(String text) {
    final stopWords = const <String>{
      'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
      'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
      'should', 'may', 'might', 'can', 'shall', 'to', 'of', 'in', 'for',
      'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during',
      'before', 'after', 'above', 'below', 'between', 'out', 'off', 'over',
      'under', 'again', 'further', 'then', 'once', 'and', 'but', 'or',
      'nor', 'not', 'so', 'if', 'this', 'that', 'these', 'those', 'i',
      'me', 'my', 'we', 'our', 'you', 'your', 'he', 'him', 'his', 'she',
      'her', 'it', 'its', 'they', 'them', 'their', 'what', 'which', 'who',
      'whom', 'when', 'where', 'why', 'how', 'all', 'each', 'every',
      'both', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'only',
      'own', 'same', 'than', 'too', 'very',
    };

    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toSet();
  }

  /// Jaccard similarity between two token sets.
  static double _jaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0.0 : intersection / union;
  }
}

/// Internal helper for scoring chunks during re-ranking.
class _ScoredChunk {
  final RetrievedChunk chunk;
  final double adjustedScore;

  const _ScoredChunk(this.chunk, this.adjustedScore);
}
