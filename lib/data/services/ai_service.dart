// AI Service architecture for AlfaNutrition.
//
// Defines the abstract contract for all AI-powered features:
// - Chat-based AI agents (trainer, nutritionist, general)
// - Food image analysis
// - Intelligent food suggestions
// - Nutrition and exercise advice
//
// Implementations:
// - LocalAiService — offline rule-based intelligence (ships by default)
// - Future: Cloud-based LLM integration (OpenAI, Anthropic, etc.)

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// The type of AI agent handling a conversation.
enum AiAgentType {
  trainer,
  nutritionist,
  general;

  String get displayName {
    switch (this) {
      case AiAgentType.trainer:
        return 'Personal Trainer';
      case AiAgentType.nutritionist:
        return 'Nutritionist';
      case AiAgentType.general:
        return 'Assistant';
    }
  }

  String get systemPromptHint {
    switch (this) {
      case AiAgentType.trainer:
        return 'You are an expert personal trainer with deep knowledge of '
            'exercise science, programming, and injury prevention.';
      case AiAgentType.nutritionist:
        return 'You are a certified sports nutritionist with expertise in '
            'macro tracking, meal planning, and dietary optimization.';
      case AiAgentType.general:
        return 'You are a knowledgeable fitness and wellness assistant.';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

/// A single message in an AI conversation.
class AiMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;

  const AiMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory AiMessage.user(String content) => AiMessage(
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      );

  factory AiMessage.assistant(String content) => AiMessage(
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      );

  factory AiMessage.system(String content) => AiMessage(
        role: 'system',
        content: content,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// An actionable item the AI suggests the user can perform.
class AiAction {
  /// The action type identifier (e.g., 'log_food', 'start_workout',
  /// 'view_exercise', 'set_goal').
  final String type;

  /// Human-readable label for the action button.
  final String label;

  /// Payload data for the action (e.g., food item data, exercise ID).
  final Map<String, dynamic> data;

  const AiAction({
    required this.type,
    required this.label,
    this.data = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        'data': data,
      };

  factory AiAction.fromJson(Map<String, dynamic> json) => AiAction(
        type: json['type'] as String,
        label: json['label'] as String,
        data: json['data'] != null
            ? Map<String, dynamic>.from(json['data'] as Map)
            : {},
      );
}

/// Response from an AI chat interaction.
class AiChatResponse {
  /// The assistant's message content.
  final String message;

  /// Follow-up prompts the user might want to ask.
  final List<String> suggestions;

  /// Actionable items the user can tap (log food, start workout, etc.).
  final List<AiAction> actions;

  const AiChatResponse({
    required this.message,
    this.suggestions = const [],
    this.actions = const [],
  });
}

/// Result of analyzing a food image.
class FoodAnalysisResult {
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double confidence; // 0.0 – 1.0
  final String servingSize;
  final String? imageUrl;

  const FoodAnalysisResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.confidence,
    required this.servingSize,
    this.imageUrl,
  });

  /// Whether the analysis is confident enough to auto-log.
  bool get isHighConfidence => confidence >= 0.8;

  Map<String, dynamic> toJson() => {
        'foodName': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'confidence': confidence,
        'servingSize': servingSize,
        'imageUrl': imageUrl,
      };
}

/// A food suggestion returned by the AI.
class FoodSuggestion {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final String category;
  final String servingSize;

  const FoodSuggestion({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.category,
    required this.servingSize,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'category': category,
        'servingSize': servingSize,
      };
}

/// Nutrition advice from the AI nutritionist agent.
class NutritionAdvice {
  /// The main advice text.
  final String advice;

  /// Suggested macro adjustments (e.g., {'protein': '+20g', 'carbs': '-30g'}).
  final Map<String, String> macroSuggestions;

  /// Optional meal plan outline.
  final List<MealPlanEntry> mealPlan;

  const NutritionAdvice({
    required this.advice,
    this.macroSuggestions = const {},
    this.mealPlan = const [],
  });
}

/// A single entry in a suggested meal plan.
class MealPlanEntry {
  final String mealType; // breakfast, lunch, dinner, snack
  final String description;
  final double estimatedCalories;
  final double estimatedProtein;

  const MealPlanEntry({
    required this.mealType,
    required this.description,
    required this.estimatedCalories,
    required this.estimatedProtein,
  });

  Map<String, dynamic> toJson() => {
        'mealType': mealType,
        'description': description,
        'estimatedCalories': estimatedCalories,
        'estimatedProtein': estimatedProtein,
      };
}

/// Exercise advice from the AI trainer agent.
class ExerciseAdvice {
  /// The main advice text.
  final String advice;

  /// Recommended exercise IDs from the exercise database.
  final List<String> exercises;

  /// Form tips and technique cues.
  final List<String> formTips;

  const ExerciseAdvice({
    required this.advice,
    this.exercises = const [],
    this.formTips = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Abstract service contract
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for all AI-powered intelligence in AlfaNutrition.
///
/// Implementations can be swapped without touching UI code.
/// The app ships with [LocalAiService] (offline, rule-based) and is
/// architected for a future cloud-backed implementation.
abstract class AiService {
  /// Send a chat message to an AI agent and receive a response.
  ///
  /// [message] — the user's input.
  /// [agent] — which agent persona to use (defaults to general).
  /// [history] — conversation history for context continuity.
  /// [context] — additional context (current macros, workout state, etc.).
  Future<AiChatResponse> chat(
    String message, {
    AiAgentType agent = AiAgentType.general,
    List<AiMessage> history = const [],
    Map<String, dynamic>? context,
  });

  /// Analyze a food image and estimate nutrition information.
  ///
  /// Returns a [FoodAnalysisResult] with estimated macros and confidence.
  /// The local implementation returns a placeholder; cloud implementations
  /// use vision models for real analysis.
  Future<FoodAnalysisResult> analyzeFoodImage(String imagePath);

  /// Suggest foods matching a search query, optionally personalized
  /// to the user's goals and dietary preferences.
  Future<List<FoodSuggestion>> suggestFoods(
    String query, {
    Map<String, dynamic>? userContext,
  });

  /// Get personalized nutrition advice based on a question and user profile.
  Future<NutritionAdvice> getNutritionAdvice(
    String question, {
    Map<String, dynamic>? userProfile,
  });

  /// Get personalized exercise advice based on a question and user profile.
  Future<ExerciseAdvice> getExerciseAdvice(
    String question, {
    Map<String, dynamic>? userProfile,
  });
}
