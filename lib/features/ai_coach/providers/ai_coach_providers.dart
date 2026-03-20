import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:alfanutrition/data/models/ai_chat_message.dart';
import 'package:alfanutrition/data/models/chat_session.dart';
import 'package:alfanutrition/data/models/user_memory.dart';
import 'package:alfanutrition/data/models/user_profile.dart';
import 'package:alfanutrition/data/repositories/chat_history_repository.dart';
import 'package:alfanutrition/data/repositories/nutrition_repository.dart';
import 'package:alfanutrition/data/repositories/workout_repository.dart';
import 'package:alfanutrition/data/services/ai_action_executor.dart';
import 'package:alfanutrition/data/services/ai_service.dart' as svc;
import 'package:alfanutrition/data/services/local_ai_service.dart';
import 'package:alfanutrition/data/services/openai_service.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';

// ─────────────────────────── Enums ─────────────────────────────────────────

enum AiAgentType { trainer, nutritionist }

// ─────────────────────────── Model ─────────────────────────────────────────

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestions;
  final String? insightTitle;
  final IconData? insightIcon;

  /// Actions that the AI wants to execute (e.g., log a meal, log a workout).
  final List<svc.AiAction>? actions;

  /// Results from executing actions (populated after execution).
  final List<AiActionResult>? actionResults;

  /// Whether this is a system notification message (action results, errors).
  final bool isSystemNotification;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestions,
    this.insightTitle,
    this.insightIcon,
    this.actions,
    this.actionResults,
    this.isSystemNotification = false,
  });
}

// ─────────────────────────── Service Provider ──────────────────────────────

/// Automatically selects OpenAI if OPENAI_API_KEY is set in .env,
/// otherwise falls back to the offline rule-based engine.
final aiServiceProvider = Provider<svc.AiService>((ref) {
  if (OpenAiService.isConfigured) {
    return OpenAiService();
  }
  return LocalAiService();
});

// ─────────────────────────── Providers ─────────────────────────────────────

final aiAgentTypeProvider = StateProvider<AiAgentType>(
  (ref) => AiAgentType.trainer,
);

/// Repository for local chat storage.
final chatHistoryRepositoryProvider = Provider<ChatHistoryRepository>((ref) {
  return ChatHistoryRepository();
});

/// Current active session ID. Null means no session yet (will be created on first message).
final activeSessionIdProvider = StateProvider<String?>((ref) => null);

/// All chat sessions, sorted newest first.
final chatSessionsProvider = FutureProvider<List<ChatSession>>((ref) async {
  // Watch the active session to refresh when it changes
  ref.watch(activeSessionIdProvider);
  final repo = ref.read(chatHistoryRepositoryProvider);
  return repo.getSessions();
});

/// User memories for AI context.
final userMemoriesProvider = FutureProvider<List<UserMemory>>((ref) async {
  final repo = ref.read(chatHistoryRepositoryProvider);
  return repo.getMemories();
});

final aiChatMessagesProvider =
    StateNotifierProvider<AiChatNotifier, List<ChatMessage>>(
  (ref) => AiChatNotifier(ref),
);

// ─────────────────────────── Notifier ──────────────────────────────────────

class AiChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;
  static const _uuid = Uuid();

  /// The current session ID. Null until the first message is sent.
  String? _currentSessionId;

  String? get currentSessionId => _currentSessionId;

  AiChatNotifier(this._ref) : super([]) {
    _seedInitialMessages();
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Load messages from Hive for an existing session.
  Future<void> loadSession(String sessionId) async {
    _currentSessionId = sessionId;
    _ref.read(activeSessionIdProvider.notifier).state = sessionId;

    final repo = _ref.read(chatHistoryRepositoryProvider);
    final session = await repo.getSession(sessionId);
    final hiveMessages = await repo.getMessages(sessionId);

    // Restore agent type from session
    if (session != null) {
      final agentType = session.agentType == 'nutritionist'
          ? AiAgentType.nutritionist
          : AiAgentType.trainer;
      _ref.read(aiAgentTypeProvider.notifier).state = agentType;
    }

    // Convert AiChatMessage -> ChatMessage
    final messages = hiveMessages.map((m) {
      return ChatMessage(
        id: m.id,
        content: m.content,
        isUser: m.isUser,
        timestamp: m.timestamp,
        suggestions: m.suggestions.isNotEmpty ? m.suggestions : null,
        isSystemNotification: m.isSystem,
      );
    }).toList();

    state = messages;
  }

  /// Start a new chat session. Clears current messages and seeds welcome.
  void startNewSession() {
    _currentSessionId = null;
    _ref.read(activeSessionIdProvider.notifier).state = null;
    state = [];
    _seedInitialMessages();
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // Persist user message
    _persistMessage(userMsg);

    // Extract memories from user message
    _extractMemoriesFromUser(trimmed);

    // Generate AI response using the service with real user context
    _generateAiResponse(trimmed);
  }

  void clearChat() {
    startNewSession();
  }

  void switchAgent(AiAgentType type) {
    _ref.read(aiAgentTypeProvider.notifier).state = type;
    startNewSession();
  }

  // ── Persistence helpers ─────────────────────────────────────────────────

  Future<void> _persistMessage(ChatMessage msg) async {
    final repo = _ref.read(chatHistoryRepositoryProvider);
    final agentType = _ref.read(aiAgentTypeProvider);
    final agentStr =
        agentType == AiAgentType.trainer ? 'trainer' : 'nutritionist';

    // Create session on first message if needed
    if (_currentSessionId == null) {
      final sessionId = _uuid.v4();
      _currentSessionId = sessionId;
      _ref.read(activeSessionIdProvider.notifier).state = sessionId;

      // Generate title from first user message
      final title = msg.content.length > 30
          ? '${msg.content.substring(0, 30)}...'
          : msg.content;

      final session = ChatSession(
        id: sessionId,
        title: title,
        agentType: agentStr,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        messageCount: 1,
      );
      await repo.saveSession(session);
    } else {
      // Update session metadata
      final existingSession = await repo.getSession(_currentSessionId!);
      if (existingSession != null) {
        final updated = existingSession.copyWith(
          lastMessageAt: DateTime.now(),
          messageCount: existingSession.messageCount + 1,
        );
        await repo.saveSession(updated);
      }
    }

    // Save the message
    final hiveMsg = AiChatMessage(
      id: msg.id,
      role: msg.isUser
          ? 'user'
          : (msg.isSystemNotification ? 'system' : 'assistant'),
      content: msg.content,
      timestamp: msg.timestamp,
      agentType: agentStr,
      suggestions: msg.suggestions ?? [],
    );
    await repo.saveMessage(_currentSessionId!, hiveMsg);

    // Refresh sessions list
    _ref.invalidate(chatSessionsProvider);
  }

  // ── Context building ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildUserContext() {
    final profileAsync = _ref.read(userProfileProvider);
    final UserProfile profile = profileAsync.when(
      data: (p) => p,
      loading: () => UserProfile(),
      error: (_, _) => UserProfile(),
    );

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
    };
  }

  Future<Map<String, dynamic>> _buildUserContextWithMemories() async {
    final context = _buildUserContext();

    // Add memory summary
    final repo = _ref.read(chatHistoryRepositoryProvider);
    final memorySummary = await repo.getMemorySummary();
    if (memorySummary.isNotEmpty) {
      context['memorySummary'] = memorySummary;
    }

    // Add today's nutrition summary
    try {
      final todayNutrition = await _getTodayNutrition();
      context['todayCalories'] = todayNutrition['calories'];
      context['todayProtein'] = todayNutrition['protein'];
      context['todayCarbs'] = todayNutrition['carbs'];
      context['todayFats'] = todayNutrition['fats'];
      context['mealsLoggedToday'] = todayNutrition['count'];
      context['todayMealsCount'] = todayNutrition['count'];
    } catch (e) {
      debugPrint('Failed to load today\'s nutrition: $e');
    }

    // Add this week's workout summary
    try {
      final weekWorkouts = await _getWeekWorkoutCount();
      context['workoutsThisWeek'] = weekWorkouts;
    } catch (e) {
      debugPrint('Failed to load weekly workouts: $e');
    }

    // Add last workout info
    try {
      final lastWorkout = await _getLastWorkoutInfo();
      if (lastWorkout != null) {
        context['lastWorkoutDate'] = lastWorkout['date'];
        context['lastWorkoutName'] = lastWorkout['name'];
      }
    } catch (e) {
      debugPrint('Failed to load last workout: $e');
    }

    // Add last meal time for proactive nudges
    try {
      final lastMeal = await _getLastMealTime();
      if (lastMeal != null) {
        context['lastMealTime'] = lastMeal;
      }
    } catch (e) {
      debugPrint('Failed to load last meal time: $e');
    }

    return context;
  }

  /// Get info about the last workout.
  Future<Map<String, dynamic>?> _getLastWorkoutInfo() async {
    final workoutRepo = WorkoutRepository();
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final workouts = await workoutRepo.getWorkoutsInRange(monthAgo, now);
    if (workouts.isEmpty) return null;

    // Sort by date descending
    workouts.sort((a, b) {
      final aDate = a['date'] is String ? DateTime.tryParse(a['date'] as String) : a['date'] as DateTime?;
      final bDate = b['date'] is String ? DateTime.tryParse(b['date'] as String) : b['date'] as DateTime?;
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    final latest = workouts.first;
    final date = latest['date'] is String ? latest['date'] : (latest['date'] as DateTime?)?.toIso8601String();
    return {
      'date': date,
      'name': latest['name'] as String? ?? 'Workout',
    };
  }

  /// Get the time of the last logged meal today.
  Future<String?> _getLastMealTime() async {
    final nutritionRepo = NutritionRepository();
    final now = DateTime.now();
    final meals = await nutritionRepo.getMealsForDate(now);
    if (meals.isEmpty) return null;

    // Find the latest meal time
    DateTime? latest;
    for (final meal in meals) {
      final dateStr = meal['date'] as String?;
      if (dateStr != null) {
        final d = DateTime.tryParse(dateStr);
        if (d != null && (latest == null || d.isAfter(latest))) {
          latest = d;
        }
      }
    }
    return latest?.toIso8601String();
  }

  /// Get today's nutrition totals from the NutritionRepository.
  Future<Map<String, dynamic>> _getTodayNutrition() async {
    final nutritionRepo = NutritionRepository();
    final now = DateTime.now();
    final meals = await nutritionRepo.getMealsForDate(now);

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    for (final meal in meals) {
      calories += (meal['calories'] as num?)?.toDouble() ?? 0;
      protein += (meal['protein'] as num?)?.toDouble() ?? 0;
      carbs += (meal['carbs'] as num?)?.toDouble() ?? 0;
      fats += (meal['fat'] as num?)?.toDouble() ?? 0;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'count': meals.length,
    };
  }

  /// Count workouts in the last 7 days from the WorkoutRepository.
  Future<int> _getWeekWorkoutCount() async {
    final workoutRepo = WorkoutRepository();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final workouts = await workoutRepo.getWorkoutsInRange(weekAgo, now);
    return workouts.length;
  }

  svc.AiService get _aiService => _ref.read(aiServiceProvider);

  // ── AI response via service ───────────────────────────────────────────────

  Future<void> _generateAiResponse(String text) async {
    final agentType = _ref.read(aiAgentTypeProvider);
    final context = await _buildUserContextWithMemories();

    // Map local AiAgentType to service-layer AiAgentType
    final serviceAgent = agentType == AiAgentType.trainer
        ? svc.AiAgentType.trainer
        : svc.AiAgentType.nutritionist;

    // Build conversation history from recent messages (last 10 for context).
    // Exclude the current user message (already appended to state) and
    // the initial welcome message.
    final recentMessages = state
        .where((m) => m.content != text || !m.isUser) // skip current msg
        .where((m) => !m.isSystemNotification) // skip system notifications
        .skip(1) // skip the welcome/seed message
        .toList();
    // Take last 10 messages for context window
    final historySlice = recentMessages.length > 10
        ? recentMessages.sublist(recentMessages.length - 10)
        : recentMessages;
    final history = historySlice
        .map((m) => svc.AiMessage(
              role: m.isUser ? 'user' : 'assistant',
              content: m.content,
              timestamp: m.timestamp,
            ))
        .toList();

    try {
      // Pass ref to OpenAiService so it can run the RAG pipeline
      final service = _aiService;
      final svc.AiChatResponse response;
      if (service is OpenAiService) {
        response = await service.chat(
          text,
          agent: serviceAgent,
          history: history,
          context: context,
          ref: _ref,
        );
      } else {
        // Pass history to LocalAiService for context-aware intent classification
        response = await service.chat(
          text,
          agent: serviceAgent,
          history: history,
          context: context,
        );
      }

      // Track conversation behavior as memories
      _trackConversationBehavior(text);

      if (!mounted) return;

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        content: response.message,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions:
            response.suggestions.isNotEmpty ? response.suggestions : null,
        actions: response.actions.isNotEmpty ? response.actions : null,
      );
      state = [...state, aiMsg];

      // Persist AI message
      _persistMessage(aiMsg);

      // Extract memories from AI response
      _extractMemoriesFromAi(response.message);

      // Auto-execute any actions the AI returned
      if (response.actions.isNotEmpty) {
        await _executeActions(response.actions);
      }
    } catch (e, st) {
      debugPrint('AI Coach error: $e\n$st');
      if (!mounted) return;

      // Show the real error in debug builds so issues are visible.
      final detail = kDebugMode ? '\n\nDebug: $e' : '';
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        content: 'Something went wrong. Try asking again.$detail',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMsg];
    }
  }

  // ── Action execution ─────────────────────────────────────────────────────

  Future<void> _executeActions(List<svc.AiAction> actions) async {
    final executor = _ref.read(aiActionExecutorProvider);
    final results = await executor.executeAll(actions);

    if (!mounted) return;

    // Build a summary of what was executed
    final successParts = <String>[];
    final errorParts = <String>[];

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      if (result.success) {
        successParts.add(result.message);

        // Track successful actions as behavior memories
        final action = actions[i];
        if (action.type == 'log_meal') {
          final foodName = action.data['name'] as String? ?? '';
          final mealType = action.data['meal_type'] as String? ?? '';
          _saveMemory(
            'Logged $foodName${mealType.isNotEmpty ? ' for $mealType' : ''} at ${DateTime.now().hour}:00',
            'behavior_pattern',
          );
        } else if (action.type == 'log_workout') {
          final dayName = const [
            '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday',
          ][DateTime.now().weekday];
          _saveMemory(
            'Logged a workout on $dayName',
            'behavior_pattern',
          );
        }
      } else {
        errorParts.add(result.message);
      }
    }

    // Add a system notification showing what actions were taken
    if (successParts.isNotEmpty || errorParts.isNotEmpty) {
      final buffer = StringBuffer();
      if (successParts.isNotEmpty) {
        buffer.writeln(successParts.join('\n'));
      }
      if (errorParts.isNotEmpty) {
        buffer.writeln(errorParts.map((e) => 'Failed: $e').join('\n'));
      }

      final notif = ChatMessage(
        id: _uuid.v4(),
        content: buffer.toString().trim(),
        isUser: false,
        timestamp: DateTime.now(),
        isSystemNotification: true,
        actionResults: results,
        insightTitle:
            successParts.isNotEmpty ? 'Action completed' : 'Action failed',
        insightIcon:
            successParts.isNotEmpty ? Icons.check_circle : Icons.error,
      );
      state = [...state, notif];
      _persistMessage(notif);
    }
  }

  // ── Memory extraction ──────────────────────────────────────────────────────

  /// Extract memories from user messages based on keyword patterns.
  void _extractMemoriesFromUser(String text) {
    final lower = text.toLowerCase();

    final patterns = <RegExp, String>{
      // Preferences
      RegExp(r"i prefer\s+(.+)", caseSensitive: false): 'preference',
      RegExp(r"i like\s+(.+)", caseSensitive: false): 'preference',
      RegExp(r"i usually\s+(.+)", caseSensitive: false): 'preference',
      RegExp(r"i always\s+(.+)", caseSensitive: false): 'preference',
      RegExp(r"i('m| am) (\d+)\s*(years? old|yo)", caseSensitive: false):
          'preference',
      RegExp(r"my favorite\s+(.+)", caseSensitive: false): 'preference',
      // Health & conditions
      RegExp(r"i('m| am) allergic to\s+(.+)", caseSensitive: false): 'health',
      RegExp(r"i have\s+(a |an )?(injury|condition|diabetes|asthma|back pain|knee pain|shoulder pain|heart condition|high blood pressure)",
              caseSensitive: false):
          'health',
      RegExp(r"i('m| am) (recovering|injured|dealing with)", caseSensitive: false):
          'health',
      // Diet
      RegExp(r"i can'?t eat\s+(.+)", caseSensitive: false): 'diet',
      RegExp(r"i('m| am) (vegan|vegetarian|keto|paleo|gluten.free|lactose.intolerant|halal|kosher|pescatarian)",
              caseSensitive: false):
          'diet',
      RegExp(r"i don'?t eat\s+(.+)", caseSensitive: false): 'diet',
      RegExp(r"i('m| am) intolerant to\s+(.+)", caseSensitive: false): 'diet',
      // Goals
      RegExp(r"my goal is\s+(.+)", caseSensitive: false): 'goal',
      RegExp(r"i('m| am) trying to\s+(.+)", caseSensitive: false): 'goal',
      RegExp(r"i want to\s+(lose|gain|build|improve|increase|decrease)\s+(.+)",
              caseSensitive: false):
          'goal',
      RegExp(r"i('m| am) training for\s+(.+)", caseSensitive: false): 'goal',
      // Training
      RegExp(r"i work ?out\s+(\d+)\s+times", caseSensitive: false): 'training',
      RegExp(r"i train\s+(\d+)\s+(days?|times)", caseSensitive: false): 'training',
      RegExp(r"i do\s+(push.pull.legs|ppl|upper.lower|bro.split|full.body)",
              caseSensitive: false):
          'training',
      RegExp(r"my (bench|squat|deadlift|ohp)\s+(is|max)\s+(\d+)", caseSensitive: false):
          'achievement',
      // Achievements
      RegExp(r"i (just |recently )?(hit|reached|got|achieved)\s+(.+)", caseSensitive: false):
          'achievement',
      RegExp(r"my pr is\s+(.+)", caseSensitive: false): 'achievement',
      RegExp(r"i weigh\s+(\d+)", caseSensitive: false): 'preference',
    };

    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(lower);
      if (match != null) {
        // Use the original text (not lowered) for the fact
        final fact = text.length > 100 ? '${text.substring(0, 100)}...' : text;
        _saveMemory(fact, entry.value);
        break; // One memory per message max
      }
    }
  }

  /// Extract memories from AI responses (simple heuristic).
  void _extractMemoriesFromAi(String response) {
    // The AI might mention things it learned. For local AI, we skip this.
    // For OpenAI, we could parse structured memory hints.
    // For now, no-op for AI responses — user messages are the primary source.
  }

  Future<void> _saveMemory(String fact, String category) async {
    if (_currentSessionId == null) return;

    final repo = _ref.read(chatHistoryRepositoryProvider);
    final memory = UserMemory(
      id: _uuid.v4(),
      fact: fact,
      category: category,
      createdAt: DateTime.now(),
      lastReferencedAt: DateTime.now(),
      sourceSessionId: _currentSessionId!,
    );
    await repo.saveMemory(memory);
    _ref.invalidate(userMemoriesProvider);
  }

  // ── Seed Messages ────────────────────────────────────────────────────────

  void _seedInitialMessages() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final agentType = _ref.read(aiAgentTypeProvider);
    final isTrainer = agentType == AiAgentType.trainer;

    // Pull user profile for personalized welcome
    final userContext = _buildUserContext();
    final name = userContext['name'] as String?;
    final nameGreeting =
        (name != null && name.isNotEmpty) ? ', $name' : '';

    final welcomeMsg = ChatMessage(
      id: _uuid.v4(),
      content:
          '$greeting$nameGreeting! I\'m your ${isTrainer ? 'Trainer' : 'Nutritionist'}. '
          'Ask me anything about ${isTrainer ? 'training, splits, recovery, or exercises' : 'calories, macros, meal timing, or supplements'}.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      suggestions: isTrainer
          ? [
              'Recommend a workout split',
              'How do I progressively overload?',
              'When should I deload?',
            ]
          : [
              'What should my macros be?',
              'How much protein do I need?',
              'How many calories do I need?',
            ],
    );

    state = [welcomeMsg];

    // Generate proactive insights asynchronously
    _addProactiveInsight(isTrainer);
  }

  /// Generates a proactive insight message if relevant data is available.
  Future<void> _addProactiveInsight(bool isTrainer) async {
    try {
      final fullContext = await _buildUserContextWithMemories();
      final service = _aiService;
      if (service is LocalAiService) {
        final insights = service.generateInsights(fullContext);
        if (insights.isNotEmpty && mounted) {
          // Pick the most relevant insight (first one has highest priority)
          final insight = insights.first;

          // Determine icon and category
          IconData icon = Icons.lightbulb_outline;
          String title = 'Insight';
          if (insight.contains('protein') || insight.contains('calorie') || insight.contains('eat') || insight.contains('meal')) {
            icon = Icons.restaurant_outlined;
            title = 'Nutrition Insight';
          } else if (insight.contains('workout') || insight.contains('training') || insight.contains('exercise')) {
            icon = Icons.fitness_center_outlined;
            title = 'Training Insight';
          } else if (insight.contains('consistency') || insight.contains('great') || insight.contains('streak')) {
            icon = Icons.emoji_events_outlined;
            title = 'Achievement';
          }

          final insightMsg = ChatMessage(
            id: _uuid.v4(),
            content: insight,
            isUser: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
            insightTitle: title,
            insightIcon: icon,
            suggestions: isTrainer
                ? ['Log a workout', 'What should I train today?', 'Show my progress']
                : ['Log a meal', 'How am I doing today?', 'Show my macros'],
          );
          state = [...state, insightMsg];
        }
      }
    } catch (e) {
      debugPrint('Failed to generate proactive insight: $e');
    }
  }

  // ── Conversation behavior tracking ────────────────────────────────────────

  /// Track conversation behavior patterns as user memories.
  void _trackConversationBehavior(String text) {
    final lower = text.toLowerCase();

    // Track detail preference
    final isFollowUp = lower.startsWith('more') ||
        lower.startsWith('can you explain') ||
        lower.startsWith('tell me more') ||
        lower.startsWith('what about') ||
        lower.startsWith('and ') ||
        lower.contains('more detail') ||
        lower.contains('elaborate');

    if (isFollowUp) {
      _saveMemory('User prefers detailed explanations', 'preference');
    }

    // Track common food logging patterns
    final foodLogPatterns = [
      RegExp(r'(i |just )?(had|ate|eaten)\s+(.+)', caseSensitive: false),
      RegExp(r'log\s+(.+)', caseSensitive: false),
    ];
    for (final pattern in foodLogPatterns) {
      if (pattern.hasMatch(lower)) {
        final hour = DateTime.now().hour;
        final mealPeriod = hour < 11
            ? 'breakfast'
            : hour < 15
                ? 'lunch'
                : hour < 18
                    ? 'snack'
                    : 'dinner';
        _saveMemory(
          'User logs meals around ${hour}:00 ($mealPeriod time)',
          'behavior_pattern',
        );
        break;
      }
    }

    // Track workout conversation patterns
    if (lower.contains('workout') ||
        lower.contains('exercise') ||
        lower.contains('training') ||
        lower.contains('bench') ||
        lower.contains('squat') ||
        lower.contains('deadlift')) {
      final dayName = const [
        '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ][DateTime.now().weekday];
      _saveMemory(
        'User discusses workouts on $dayName',
        'behavior_pattern',
      );
    }
  }
}
