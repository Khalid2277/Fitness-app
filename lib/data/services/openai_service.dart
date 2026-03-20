import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:alfanutrition/data/services/ai_service.dart';
import 'package:alfanutrition/data/services/rag_config.dart';
import 'package:alfanutrition/data/services/rag_service.dart';

/// OpenAI-backed AI service for AlfaNutrition.
///
/// Uses the Chat Completions API to power the AI Coach (trainer + nutritionist).
/// Requires a valid `OPENAI_API_KEY` in the `.env` file.
///
/// When Pinecone is configured the service automatically augments prompts
/// with retrieved knowledge via [RagService]. When it is not configured the
/// service falls back to the original context-only prompting — zero cost.
class OpenAiService implements AiService {
  static const _baseUrl = 'https://api.openai.com/v1';

  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  String get _model => dotenv.env['OPENAI_MODEL'] ?? 'gpt-5.4-mini';

  /// Whether the OpenAI API key is configured and non-empty.
  static bool get isConfigured {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    return key.isNotEmpty;
  }

  /// Whether the RAG pipeline (Pinecone) is configured and available.
  static bool get isRagConfigured => RagConfig.isConfigured;

  /// Lazily-created RAG service instance.
  RagService? _ragService;
  RagService get _rag => _ragService ??= RagService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  // ─────────────────────────── Chat ──────────────────────────────────────────

  @override
  Future<AiChatResponse> chat(
    String message, {
    AiAgentType agent = AiAgentType.general,
    List<AiMessage> history = const [],
    Map<String, dynamic>? context,
    Ref? ref,
  }) async {
    String systemPrompt;
    int maxTokens;

    // Use RAG-augmented prompt when Pinecone is configured and a Ref is
    // available for accessing Supabase providers.
    if (isRagConfigured && ref != null) {
      try {
        final ragResult = await _rag.retrieve(
          query: message,
          agent: agent,
          ref: ref,
        );
        systemPrompt = ragResult.augmentedSystemPrompt;
        // Allow longer responses when grounded in retrieved knowledge.
        maxTokens = ragResult.chunks.isNotEmpty ? 1200 : 800;
      } catch (e) {
        debugPrint('RAG pipeline error, falling back to context-only: $e');
        systemPrompt = _buildSystemPrompt(agent, context, message);
        maxTokens = 800;
      }
    } else {
      systemPrompt = _buildSystemPrompt(agent, context, message);
      maxTokens = 800;
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {'role': m.role, 'content': m.content}),
      {'role': 'user', 'content': message},
    ];

    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'temperature': 0.7,
      'max_completion_tokens': maxTokens,
    });

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      final errorMsg = error['error']?['message'] ?? 'Unknown error';
      throw Exception(
        'OpenAI API error (${response.statusCode}): $errorMsg',
      );
    }

    final data = jsonDecode(response.body);
    final content =
        data['choices'][0]['message']['content'] as String? ?? '';

    // Parse structured actions from the response (JSON blocks)
    final actions = _extractActions(content);

    // Parse suggestions from the response if the model included them
    final suggestions = _extractSuggestions(content, agent, message);

    return AiChatResponse(
      message: _cleanResponse(content),
      suggestions: suggestions,
      actions: actions,
    );
  }

  // ─────────────────────────── Food Image Analysis ───────────────────────────

  @override
  Future<FoodAnalysisResult> analyzeFoodImage(String imagePath) async {
    // Vision analysis requires base64 encoding the image
    // For now, return a placeholder — full implementation requires
    // reading the image file and sending to GPT-4 Vision
    return const FoodAnalysisResult(
      foodName: 'Unable to analyze',
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
      confidence: 0,
      servingSize: 'N/A',
    );
  }

  // ─────────────────────────── Food Suggestions ──────────────────────────────

  @override
  Future<List<FoodSuggestion>> suggestFoods(
    String query, {
    Map<String, dynamic>? userContext,
  }) async {
    final goal = userContext?['goal'] as String? ?? 'generalFitness';

    final response = await chat(
      'Suggest 5 specific foods for someone searching "$query" with a $goal goal. '
      'For each food, provide: name, calories, protein (g), carbs (g), fat (g), '
      'category, and serving size. Format as JSON array.',
      agent: AiAgentType.nutritionist,
      context: userContext,
    );

    // Try to parse structured data from the response
    try {
      final jsonMatch =
          RegExp(r'\[[\s\S]*?\]').firstMatch(response.message);
      if (jsonMatch != null) {
        final list = jsonDecode(jsonMatch.group(0)!) as List;
        return list
            .map((item) => FoodSuggestion(
                  name: item['name'] as String? ?? query,
                  calories: (item['calories'] as num?)?.toDouble() ?? 0,
                  protein: (item['protein'] as num?)?.toDouble() ?? 0,
                  carbs: (item['carbs'] as num?)?.toDouble() ?? 0,
                  fats: (item['fat'] as num?)?.toDouble() ?? 0,
                  category: item['category'] as String? ?? 'General',
                  servingSize: item['servingSize'] as String? ?? '1 serving',
                ))
            .toList();
      }
    } catch (_) {
      // If parsing fails, return empty — the chat response is still useful
    }

    return [];
  }

  // ─────────────────────────── Nutrition Advice ──────────────────────────────

  @override
  Future<NutritionAdvice> getNutritionAdvice(
    String question, {
    Map<String, dynamic>? userProfile,
  }) async {
    final response = await chat(
      question,
      agent: AiAgentType.nutritionist,
      context: userProfile,
    );

    return NutritionAdvice(advice: response.message);
  }

  // ─────────────────────────── Exercise Advice ───────────────────────────────

  @override
  Future<ExerciseAdvice> getExerciseAdvice(
    String question, {
    Map<String, dynamic>? userProfile,
  }) async {
    final response = await chat(
      question,
      agent: AiAgentType.trainer,
      context: userProfile,
    );

    return ExerciseAdvice(advice: response.message);
  }

  // ─────────────────────────── System Prompt Builder ─────────────────────────

  /// Build the context-only system prompt (used when RAG is not configured).
  ///
  /// Incorporates user profile, time-of-day coaching cues, and smart
  /// detection hints for meal/workout logging.
  String _buildSystemPrompt(
    AiAgentType agent,
    Map<String, dynamic>? context,
    String userMessage,
  ) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final hour = now.hour;

    // ── Persona ──────────────────────────────────────────────────────────

    buffer.writeln(_buildPersona(agent, context));
    buffer.writeln();

    // ── Core instructions ────────────────────────────────────────────────

    buffer.writeln('RESPONSE STYLE:');
    buffer.writeln(
        '- Be warm but efficient. Address the user by name when natural.');
    buffer.writeln(
        '- Give specific, actionable advice grounded in their actual numbers '
        '(weight, targets, goal). Never give generic advice when you have '
        'their data.');
    buffer.writeln('- Use metric units (kg, cm, kcal, grams).');
    buffer.writeln(
        '- Keep responses under 200 words for quick questions. Go longer '
        'only when the user asks for detail or a plan.');
    buffer.writeln(
        '- Use ** to bold key terms, numbers, and food/exercise names.');
    buffer.writeln('- Use bullet points (- ) for lists of 3+ items.');
    buffer.writeln(
        '- Use emoji sparingly but effectively: '
        'use a checkmark for completed items, a fire emoji for PRs or intensity, '
        'a flexed bicep for encouragement, a warning sign for caution.');
    buffer.writeln(
        '- End with 1-2 brief, contextually relevant follow-up questions '
        'or concrete next steps.');
    buffer.writeln();

    // ── Contextual coaching based on time of day ─────────────────────────

    buffer.writeln('CONTEXTUAL AWARENESS:');
    buffer.writeln('- Current time: ${_formatTime(hour)}');
    if (hour >= 5 && hour < 10) {
      buffer.writeln(
          '- It is morning. Lean toward motivational energy, morning routine '
          'tips, breakfast suggestions, and pre-workout preparation.');
    } else if (hour >= 10 && hour < 14) {
      buffer.writeln(
          '- It is midday. Focus on lunch ideas, mid-workout energy, and '
          'staying on track with daily targets.');
    } else if (hour >= 14 && hour < 17) {
      buffer.writeln(
          '- It is afternoon. Good time for workout reminders, pre-workout '
          'nutrition, or afternoon snack suggestions.');
    } else if (hour >= 17 && hour < 21) {
      buffer.writeln(
          '- It is evening. Focus on dinner planning, post-workout recovery, '
          'and reviewing daily progress against targets.');
    } else {
      buffer.writeln(
          '- It is late night. Emphasize recovery, sleep quality, light '
          'snacks if needed, and preparing for tomorrow.');
    }
    buffer.writeln();

    // ── Smart logging detection hints ────────────────────────────────────

    buffer.writeln('SMART LOGGING:');
    buffer.writeln(
        'When the user describes food they ate or are eating, treat it as an '
        'implicit log request. Patterns to recognize:');
    buffer.writeln(
        '- Direct logging: "log ...", "track ...", "add ...", "record ..."');
    buffer.writeln(
        '- Past tense eating: "I had ...", "I ate ...", "I just had ...", '
        '"I just ate ...", "breakfast was ...", "for lunch I had ..."');
    buffer.writeln(
        '- Present tense: "I\'m eating ...", "I\'m having ...", '
        '"snacking on ...", "drinking ..."');
    buffer.writeln(
        '- Meal labels: "breakfast: ...", "lunch: ...", "dinner: ...", '
        '"snack: ..."');
    buffer.writeln(
        '- Quantities with units: "200g chicken", "2 cups rice", '
        '"3 eggs", "a protein shake", "a handful of almonds"');
    buffer.writeln(
        'For all of these, estimate macros accurately and include a log_meal '
        'action block. Infer the meal_type from context (time of day, '
        'explicit label, or food type). When quantities are vague, use '
        'reasonable standard serving sizes and note your assumption.');
    buffer.writeln();

    buffer.writeln(
        'When the user describes a workout, treat it as an implicit log '
        'request. Patterns to recognize:');
    buffer.writeln(
        '- Direct: "log workout", "track my workout", "record my session"');
    buffer.writeln(
        '- Descriptions: "did 3 sets of bench at 80kg for 10 reps", '
        '"squats 100kg 5x5", "ran 5km in 25 minutes"');
    buffer.writeln(
        '- Session summaries: "today: chest and triceps", '
        '"did push day", "hit legs today"');
    buffer.writeln(
        '- Freeform: "benched 80kg, then did incline for 3x12, '
        'finished with cable flies"');
    buffer.writeln(
        'For workout descriptions, parse exercise names, sets, reps, and '
        'weights. Use the exercise_id format "kebab-case-name" (e.g., '
        '"barbell-bench-press"). Map common shorthand: "bench" = '
        '"barbell-bench-press", "squat" = "barbell-back-squat", '
        '"deadlift" = "conventional-deadlift", "ohp" = '
        '"barbell-overhead-press". Estimate duration from the number of '
        'exercises (~8-10 min per exercise). Always include a log_workout '
        'action block.');
    buffer.writeln();

    // ── Action block instructions ────────────────────────────────────────

    buffer.writeln('DATABASE ACTIONS:');
    buffer.writeln(
        'When the user asks you to log, record, or track something (or when '
        'you detect implicit logging as described above), include a JSON '
        'action block in your response. The app will parse and execute it.');
    buffer.writeln('Wrap actions in ```action``` code fences. Examples:');
    buffer.writeln();
    buffer.writeln('To log a meal:');
    buffer.writeln('```action');
    buffer.writeln(
        '{"type":"log_meal","label":"Log Chicken Breast","data":{"name":"Chicken Breast","calories":165,"protein":31,"carbs":0,"fats":3.6,"fiber":0,"meal_type":"lunch","serving_size":100,"serving_unit":"g"}}');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('To log a workout:');
    buffer.writeln('```action');
    buffer.writeln(
        '{"type":"log_workout","label":"Log Push Day","data":{"name":"Push Day","duration_minutes":60,"exercises":[{"name":"Bench Press","exercise_id":"barbell-bench-press","primary_muscle":"chest","sets":[{"weight":80,"reps":5},{"weight":80,"reps":5},{"weight":80,"reps":5}]}]}}');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('To log body metrics:');
    buffer.writeln('```action');
    buffer.writeln(
        '{"type":"log_body_metric","label":"Log Weight","data":{"weight":80.5}}');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('To update weight only:');
    buffer.writeln('```action');
    buffer.writeln(
        '{"type":"update_weight","label":"Update Weight","data":{"weight":80.5}}');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln(
        'Supported action types: log_meal, log_workout, log_body_metric, '
        'update_weight, update_profile.');
    buffer.writeln(
        'IMPORTANT: For pure advice-only questions with no food or workout '
        'description, do NOT include action blocks.');
    buffer.writeln(
        'Always include your conversational response text OUTSIDE the action block.');
    buffer.writeln();

    // ── User profile context ─────────────────────────────────────────────

    if (context != null && context.isNotEmpty) {
      buffer.writeln('USER PROFILE (use these numbers in your advice):');
      final name = context['name'];
      if (name != null && name.toString().isNotEmpty) {
        buffer.writeln('- Name: $name');
      }
      final weight = context['weight'];
      if (weight != null) buffer.writeln('- Current weight: ${weight}kg');
      final height = context['height'];
      if (height != null) buffer.writeln('- Height: ${height}cm');
      final age = context['age'];
      if (age != null) buffer.writeln('- Age: $age years');

      final goal = context['goal'];
      if (goal != null) {
        buffer.writeln('- Goal: ${_humanizeGoal(goal.toString())}');
      }
      final level = context['level'];
      if (level != null) {
        buffer.writeln(
            '- Experience level: ${_humanizeLevel(level.toString())}');
      }

      final workoutDays = context['workoutDaysPerWeek'];
      if (workoutDays != null) {
        buffer.writeln('- Training frequency: ${workoutDays}x per week');
      }

      final calories = context['dailyCalorieTarget'];
      if (calories != null) {
        buffer.writeln('- Daily calorie target: $calories kcal');
      }
      final protein = context['proteinTarget'];
      if (protein != null) buffer.writeln('- Protein target: ${protein}g');
      final carbs = context['carbsTarget'];
      if (carbs != null) buffer.writeln('- Carbs target: ${carbs}g');
      final fats = context['fatsTarget'];
      if (fats != null) buffer.writeln('- Fat target: ${fats}g');

      // Memory summary from past conversations
      final memorySummary = context['memorySummary'];
      if (memorySummary != null && memorySummary.toString().isNotEmpty) {
        buffer.writeln();
        buffer.writeln(
            'USER MEMORIES (things the user has shared in past conversations):');
        buffer.writeln(memorySummary);
      }

      buffer.writeln();

      // ── Proactive coaching cues based on user data ─────────────────────

      _addCoachingCues(buffer, context, hour);
    }

    return buffer.toString();
  }

  /// Build a rich persona description based on agent type and user context.
  String _buildPersona(AiAgentType agent, Map<String, dynamic>? context) {
    final level = context?['level']?.toString() ?? 'intermediate';
    final goal = context?['goal']?.toString() ?? 'generalFitness';

    // Adjust communication style based on experience level
    String toneGuide;
    switch (level) {
      case 'beginner':
        toneGuide = 'Explain concepts simply, avoid jargon, and be extra '
            'encouraging. Break complex topics into small steps. Celebrate '
            'every win no matter how small.';
      case 'advanced':
        toneGuide = 'Use precise technical language. Skip basic explanations '
            'unless asked. Focus on optimisation, periodization, and '
            'fine-tuning. Challenge them to push limits safely.';
      default: // intermediate
        toneGuide = 'Balance clarity with depth. Use technical terms but '
            'briefly explain uncommon ones. Encourage progressive overload '
            'and consistency.';
    }

    switch (agent) {
      case AiAgentType.trainer:
        return 'You are a world-class personal trainer and strength coach '
            'inside the AlfaNutrition fitness app. You have deep expertise '
            'in exercise science, hypertrophy programming, powerlifting, '
            'injury prevention, and mobility. You design workouts, critique '
            'form, suggest progressions, and help users hit PRs safely.\n\n'
            'Communication style: $toneGuide\n'
            'The user\'s primary goal is ${_humanizeGoal(goal)} — keep '
            'this in mind when recommending exercises, rep ranges, rest '
            'periods, and training splits.';
      case AiAgentType.nutritionist:
        return 'You are a certified sports nutritionist and meal planning '
            'expert inside the AlfaNutrition fitness app. You specialize in '
            'macro tracking, calorie management, meal timing, supplement '
            'science, and dietary optimization for athletic performance.\n\n'
            'Communication style: $toneGuide\n'
            'The user\'s primary goal is ${_humanizeGoal(goal)} — tailor '
            'all calorie, macro, and meal advice to support this goal.';
      case AiAgentType.general:
        return 'You are a knowledgeable fitness and wellness coach inside '
            'the AlfaNutrition app. You cover training, nutrition, recovery, '
            'and general wellness. You help users track their progress, stay '
            'consistent, and make informed decisions about their health.\n\n'
            'Communication style: $toneGuide';
    }
  }

  /// Inject proactive coaching cues based on user data and time of day.
  void _addCoachingCues(
    StringBuffer buffer,
    Map<String, dynamic> context,
    int hour,
  ) {
    buffer.writeln('COACHING CUES (use these to add proactive value):');

    final goal = context['goal']?.toString() ?? '';
    final calories = context['dailyCalorieTarget'];
    final protein = context['proteinTarget'];
    final weight = context['weight'];
    final level = context['level']?.toString() ?? 'intermediate';

    // Goal-specific coaching
    if (goal == 'fatLoss') {
      buffer.writeln(
          '- User is cutting. Prioritize protein retention, moderate '
          'deficit adherence, and sustainable habits. Watch for signs of '
          'excessive restriction.');
    } else if (goal == 'hypertrophy') {
      buffer.writeln(
          '- User is building muscle. Emphasize progressive overload, '
          'adequate protein (aim for 1.8-2.2g/kg), and slight caloric '
          'surplus. Encourage volume tracking.');
    } else if (goal == 'strength') {
      buffer.writeln(
          '- User is training for strength. Focus on compound lifts, '
          'lower rep ranges (3-6), adequate rest between sets (3-5 min), '
          'and periodized programming.');
    } else if (goal == 'endurance') {
      buffer.writeln(
          '- User is training for endurance. Emphasize carb timing, '
          'hydration, steady-state work, and recovery nutrition.');
    }

    // Level-specific reminders
    if (level == 'beginner') {
      buffer.writeln(
          '- Beginner: Focus on building habits, learning proper form, '
          'and building a consistent routine before optimizing. Full-body '
          'or upper/lower splits work best at this stage.');
    }

    // Time-based nutrition nudges
    if (calories != null && protein != null) {
      if (hour < 12) {
        buffer.writeln(
            '- Morning context: If the user asks about food, suggest '
            'front-loading protein early in the day to hit their '
            '${protein}g target.');
      } else if (hour >= 20) {
        buffer.writeln(
            '- Evening context: If discussing nutrition, consider what '
            'they might still need to hit their $calories kcal / '
            '${protein}g protein targets for the day.');
      }
    }

    // Weight-specific protein calculation
    if (weight != null && protein != null) {
      final w = (weight as num).toDouble();
      final p = (protein as num).toDouble();
      final perKg = (p / w).toStringAsFixed(1);
      buffer.writeln(
          '- Their protein target works out to ${perKg}g/kg body weight.');
    }

    buffer.writeln();
  }

  // ─────────────────────────── Response Parsing ──────────────────────────────

  /// Extract follow-up suggestions from the AI response.
  ///
  /// Generates contextually relevant suggestions based on the conversation
  /// topic rather than static defaults.
  List<String> _extractSuggestions(
    String content,
    AiAgentType agent,
    String userMessage,
  ) {
    final lower = userMessage.toLowerCase();

    // Contextual suggestions based on what the user asked about
    if (_looksLikeMealData(lower)) {
      return [
        'What else should I eat today?',
        'Am I on track with my macros?',
        'Suggest a high-protein snack',
      ];
    }

    if (_looksLikeWorkoutData(lower)) {
      return [
        'How should I recover?',
        'What should I eat post-workout?',
        'Was that enough volume?',
      ];
    }

    if (lower.contains('protein') || lower.contains('macro')) {
      return [
        'Best high-protein foods?',
        'How should I split my macros?',
        'Log a high-protein meal',
      ];
    }

    if (lower.contains('weight') || lower.contains('progress')) {
      return [
        'Am I losing weight fast enough?',
        'How do I break a plateau?',
        'Update my weight',
      ];
    }

    // Fallback: agent-specific defaults
    return switch (agent) {
      AiAgentType.trainer => [
          'Build me a workout',
          'How do I improve my bench?',
          'Suggest a warm-up routine',
        ],
      AiAgentType.nutritionist => [
          'What should I eat right now?',
          'Am I hitting my targets?',
          'Quick high-protein meal ideas',
        ],
      AiAgentType.general => [
          'Help me plan my day',
          'How do I stay consistent?',
        ],
    };
  }

  /// Extract structured action blocks from the AI response.
  ///
  /// Actions are wrapped in ```action``` code fences:
  /// ```action
  /// {"type":"log_meal","label":"Log Chicken","data":{...}}
  /// ```
  List<AiAction> _extractActions(String content) {
    final actions = <AiAction>[];
    final pattern = RegExp(r'```action\s*([\s\S]*?)```');
    final matches = pattern.allMatches(content);

    for (final match in matches) {
      final jsonStr = match.group(1)?.trim();
      if (jsonStr == null || jsonStr.isEmpty) continue;

      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        actions.add(AiAction.fromJson(json));
      } catch (_) {
        // Skip malformed action blocks
      }
    }

    return actions;
  }

  /// Clean up the response text (remove action blocks but preserve formatting).
  String _cleanResponse(String content) {
    return content
        // Remove action code blocks entirely from displayed text
        .replaceAll(RegExp(r'```action\s*[\s\S]*?```'), '')
        // Remove markdown headers but keep bold and bullets for rich display
        .replaceAll(RegExp(r'^#{1,3}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // ─────────────────────────── Detection Helpers ─────────────────────────────

  /// Detect whether the user message looks like a meal description that
  /// should be logged.
  static bool _looksLikeMealData(String lower) {
    // Direct log commands
    if (RegExp(r'\b(log|track|add|record)\b.*\b(meal|food|breakfast|lunch|dinner|snack)\b')
        .hasMatch(lower)) {
      return true;
    }

    // Past-tense eating patterns
    if (RegExp(r"\b(i |i've |just )?(had|ate|eaten|finished|grabbed|drank|consumed)\b")
        .hasMatch(lower)) {
      return true;
    }

    // Present-tense eating patterns
    if (RegExp(r"\b(i'm |i am )?(eating|having|snacking|drinking|munching)\b")
        .hasMatch(lower)) {
      return true;
    }

    // Meal label prefixes: "breakfast was ...", "lunch: ..."
    if (RegExp(r'\b(breakfast|lunch|dinner|snack|brunch|supper)\s*(was|:|is|-)\s*')
        .hasMatch(lower)) {
      return true;
    }

    // "for breakfast/lunch I had..."
    if (RegExp(r'\bfor\s+(breakfast|lunch|dinner|snack)\b').hasMatch(lower)) {
      return true;
    }

    // Quantities with units next to food-like words
    if (RegExp(r'\d+\s*(g|oz|cups?|tbsp|tsp|ml|pieces?|slices?|scoops?)\b')
        .hasMatch(lower)) {
      return true;
    }

    // Common food items mentioned casually
    if (RegExp(
            r'\b(protein shake|protein bar|eggs?|toast|oatmeal|chicken|rice|'
            r'salmon|steak|yogurt|almonds|banana|apple|salad|sandwich|wrap|'
            r'smoothie|cereal|pasta|pizza|burger|sushi)\b')
        .hasMatch(lower) &&
        RegExp(r"\b(had|ate|made|got|grabbed|drank|i'm having|just)\b")
            .hasMatch(lower)) {
      return true;
    }

    return false;
  }

  /// Detect whether the user message looks like a workout description that
  /// should be logged.
  static bool _looksLikeWorkoutData(String lower) {
    // Direct log commands
    if (RegExp(r'\b(log|track|record)\b.*\b(workout|session|training|exercise)\b')
        .hasMatch(lower)) {
      return true;
    }

    // Sets x reps patterns: "3x10", "5x5", "3 sets of 10"
    if (RegExp(r'\d+\s*x\s*\d+').hasMatch(lower) ||
        RegExp(r'\d+\s*sets?\s*(of\s*)?\d+\s*(reps?)?').hasMatch(lower)) {
      return true;
    }

    // Weight with exercise context: "80kg bench", "bench at 80kg"
    if (RegExp(r'\d+\s*(kg|lbs?|pounds?)\s*(for\s+)?\d*')
            .hasMatch(lower) &&
        RegExp(r'\b(bench|squat|deadlift|press|curl|row|fly|raise|dip|pull)\b')
            .hasMatch(lower)) {
      return true;
    }

    // "did/hit [muscle group] today" patterns
    if (RegExp(r'\b(did|hit|trained|worked)\b.*\b(chest|back|legs?|shoulders?|arms?|push|pull|upper|lower)\b')
        .hasMatch(lower)) {
      return true;
    }

    // "today: chest and triceps" / "today was leg day"
    if (RegExp(r'\btoday\b.*\b(chest|back|legs?|shoulders?|arms?|push|pull|upper|lower)\b')
        .hasMatch(lower)) {
      return true;
    }

    // Session duration mentions: "45 min workout", "trained for an hour"
    if (RegExp(r'\b\d+\s*(min|minute|hour)s?\s*(workout|session|training)\b')
        .hasMatch(lower)) {
      return true;
    }

    // Freeform exercise listing: "benched, then did incline..."
    if (RegExp(r'\b(benched|squatted|deadlifted|pressed|curled|rowed)\b')
        .hasMatch(lower)) {
      return true;
    }

    return false;
  }

  // ─────────────────────────── Formatting Helpers ────────────────────────────

  /// Format hour into a human-readable time-of-day string.
  static String _formatTime(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period (user local time)';
  }

  /// Convert a goal enum name into human-readable text.
  static String _humanizeGoal(String goal) {
    return switch (goal) {
      'fatLoss' => 'fat loss / cutting',
      'hypertrophy' => 'muscle building / hypertrophy',
      'strength' => 'strength gains',
      'endurance' => 'endurance / cardiovascular fitness',
      'generalFitness' => 'general fitness and health',
      _ => goal,
    };
  }

  /// Convert a level enum name into human-readable text.
  static String _humanizeLevel(String level) {
    return switch (level) {
      'beginner' => 'beginner (< 1 year training)',
      'intermediate' => 'intermediate (1-3 years training)',
      'advanced' => 'advanced (3+ years training)',
      _ => level,
    };
  }
}
