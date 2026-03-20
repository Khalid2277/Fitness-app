import 'dart:math';

import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/services/ai_service.dart';
import 'package:alfanutrition/data/services/food_database_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Intent classification result with confidence scoring
// ═══════════════════════════════════════════════════════════════════════════════

class _IntentResult {
  final _QueryIntent intent;
  final double confidence;
  final Map<String, dynamic> extractedData;
  final String? clarificationNeeded;

  const _IntentResult({
    required this.intent,
    required this.confidence,
    this.extractedData = const {},
    this.clarificationNeeded,
  });
}

enum _AgentDecision {
  autoAct,
  confirmFirst,
  askClarification,
  informOnly,
  proactiveInsight,
}

/// Offline coaching engine with multi-signal intent classification,
/// decision engine, pattern tracking, and proactive analysis.
class LocalAiService implements AiService {
  final FoodDatabaseService _foodDb;
  final _random = Random();

  LocalAiService({FoodDatabaseService? foodDatabaseService})
      : _foodDb = foodDatabaseService ?? FoodDatabaseService();

  @override
  Future<AiChatResponse> chat(
    String message, {
    AiAgentType agent = AiAgentType.general,
    List<AiMessage> history = const [],
    Map<String, dynamic>? context,
  }) async {
    await Future<void>.delayed(
      Duration(milliseconds: 300 + _random.nextInt(400)),
    );

    final profile = _extractProfile(context);
    final input = message.toLowerCase().trim();
    final originalMessage = message.trim();
    final intentResult = _classifyIntent(input, history, agent, context);
    final decision = _decideAction(intentResult, profile);

    switch (decision) {
      case _AgentDecision.askClarification:
        return _buildClarificationResponse(intentResult, profile);
      case _AgentDecision.proactiveInsight:
        return _buildProactiveResponse(profile, context);
      case _AgentDecision.autoAct:
      case _AgentDecision.confirmFirst:
      case _AgentDecision.informOnly:
        break;
    }

    switch (agent) {
      case AiAgentType.nutritionist:
        return _handleNutrition(intentResult.intent, input, profile,
            originalMessage: originalMessage, context: context);
      case AiAgentType.trainer:
        return _handleTraining(intentResult.intent, input, profile,
            originalMessage: originalMessage, context: context);
      case AiAgentType.general:
        return _handleGeneral(intentResult.intent, input, profile,
            originalMessage: originalMessage, context: context);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Proactive insights
  // ═══════════════════════════════════════════════════════════════════════════

  List<String> generateInsights(Map<String, dynamic> context) {
    final insights = <String>[];
    final profile = _extractProfile(context);
    final caloriesConsumed = (context['todayCalories'] as num?)?.toDouble() ?? 0;
    final proteinConsumed = (context['todayProtein'] as num?)?.toDouble() ?? 0;
    final mealsLogged = (context['todayMealsCount'] as int?) ?? 0;
    final hour = DateTime.now().hour;

    if (proteinConsumed > 0 && proteinConsumed < profile.proteinTarget * 0.5 && hour >= 15) {
      final remaining = (profile.proteinTarget - proteinConsumed).round();
      insights.add(
        'You\'ve had ${proteinConsumed.round()}g of protein so far — '
        'that\'s ${(proteinConsumed / profile.proteinTarget * 100).round()}% '
        'of your ${profile.proteinTarget.round()}g target. You still need '
        '${remaining}g. Consider a protein-rich meal or shake.',
      );
    }

    if (caloriesConsumed > 0) {
      final ratio = caloriesConsumed / profile.calorieTarget;
      if (ratio > 1.1) {
        insights.add(
          'You\'ve consumed ${caloriesConsumed.round()} kcal today, which '
          'is ${((ratio - 1) * 100).round()}% over your '
          '${profile.calorieTarget.round()} kcal target.',
        );
      } else if (ratio < 0.3 && hour >= 14) {
        insights.add(
          'You\'ve only logged ${caloriesConsumed.round()} kcal so far today. '
          'That\'s quite low for this time of day — make sure you\'re eating '
          'enough to fuel your workouts.',
        );
      }
    }

    if (mealsLogged == 0 && hour >= 10) {
      insights.add(
        'You haven\'t logged any meals today. Want to log what you\'ve eaten '
        'so far? Just tell me what you had.',
      );
    }

    final workoutsThisWeek = (context['workoutsThisWeek'] as int?) ?? 0;
    final dayOfWeek = DateTime.now().weekday;
    if (dayOfWeek >= 4 && workoutsThisWeek == 0 && profile.workoutDays >= 3) {
      insights.add(
        'It\'s ${_dayName(dayOfWeek)} and you haven\'t logged any workouts '
        'this week. Your target is ${profile.workoutDays} sessions per week.',
      );
    }

    final memorySummary = context['memorySummary'] as String?;
    if (memorySummary != null && memorySummary.contains('eggs') && hour < 11 && mealsLogged == 0) {
      insights.add('You usually have eggs for breakfast — want me to log that?');
    }

    return insights;
  }

  static String _dayName(int weekday) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekday >= 1 && weekday <= 7 ? names[weekday] : '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Multi-signal intent classifier
  // ═══════════════════════════════════════════════════════════════════════════

  _IntentResult _classifyIntent(String input, List<AiMessage> history, AiAgentType agent, Map<String, dynamic>? context) {
    final scores = <_QueryIntent, double>{};
    final extractedData = <String, dynamic>{};

    _applyKeywordScores(input, scores);
    _applyStructureScores(input, scores);
    _applyHistoryScores(input, history, scores);
    _applyAgentBias(agent, scores);
    _applyEntityScores(input, scores, extractedData);

    if (scores.isEmpty) {
      return const _IntentResult(intent: _QueryIntent.general, confidence: 0.3);
    }

    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topIntent = sorted.first.key;
    final topScore = sorted.first.value;
    const maxPossible = 5.0;
    final confidence = (topScore / maxPossible).clamp(0.0, 1.0);

    String? clarification;
    if (topIntent == _QueryIntent.logMeal && confidence < 0.5) {
      clarification = 'What did you have? I can help log it.';
    } else if (topIntent == _QueryIntent.logWorkout && confidence < 0.5) {
      clarification = 'What exercises did you do? Include weights if possible.';
    }

    return _IntentResult(intent: topIntent, confidence: confidence, extractedData: extractedData, clarificationNeeded: clarification);
  }

  void _applyKeywordScores(String input, Map<_QueryIntent, double> scores) {
    const keywordMap = <_QueryIntent, List<_WeightedKeyword>>{
      _QueryIntent.calories: [
        _WeightedKeyword('how many calories', 1.5), _WeightedKeyword('calorie', 1.0),
        _WeightedKeyword('calories', 1.0), _WeightedKeyword('tdee', 1.5),
        _WeightedKeyword('bmr', 1.5), _WeightedKeyword('deficit', 1.2),
        _WeightedKeyword('surplus', 1.2), _WeightedKeyword('maintenance calories', 1.5),
        _WeightedKeyword('how much should i eat', 1.3), _WeightedKeyword('caloric intake', 1.3),
      ],
      _QueryIntent.protein: [
        _WeightedKeyword('how much protein', 1.5), _WeightedKeyword('protein intake', 1.3),
        _WeightedKeyword('protein target', 1.3), _WeightedKeyword('protein', 1.0),
        _WeightedKeyword('whey', 1.0), _WeightedKeyword('casein', 1.0), _WeightedKeyword('amino', 0.8),
      ],
      _QueryIntent.macros: [
        _WeightedKeyword('what should my macros be', 1.8), _WeightedKeyword('macro split', 1.5),
        _WeightedKeyword('macros', 1.3), _WeightedKeyword('macro', 1.0),
        _WeightedKeyword('carbs', 0.8), _WeightedKeyword('fat intake', 1.0),
        _WeightedKeyword('fat target', 1.0), _WeightedKeyword('carb target', 1.0),
      ],
      _QueryIntent.mealTiming: [
        _WeightedKeyword('meal plan', 1.3), _WeightedKeyword('meal timing', 1.5),
        _WeightedKeyword('meal prep', 1.2), _WeightedKeyword('when should i eat', 1.5),
        _WeightedKeyword('pre workout meal', 1.3), _WeightedKeyword('post workout meal', 1.3),
        _WeightedKeyword('what to eat', 1.0), _WeightedKeyword('eating schedule', 1.3),
      ],
      _QueryIntent.workoutSplit: [
        _WeightedKeyword('workout split', 1.8), _WeightedKeyword('training split', 1.8),
        _WeightedKeyword('recommend a split', 1.5), _WeightedKeyword('best split', 1.5),
        _WeightedKeyword('how should i split', 1.5), _WeightedKeyword('ppl', 1.3),
        _WeightedKeyword('push pull legs', 1.5), _WeightedKeyword('upper lower', 1.3),
        _WeightedKeyword('full body', 1.0), _WeightedKeyword('bro split', 1.3),
        _WeightedKeyword('how many days', 0.8),
      ],
      _QueryIntent.progressiveOverload: [
        _WeightedKeyword('progressive overload', 2.0), _WeightedKeyword('plateau', 1.3),
        _WeightedKeyword('not progressing', 1.3), _WeightedKeyword('stalled', 1.2),
        _WeightedKeyword('stuck', 0.8), _WeightedKeyword("can't increase", 1.2),
        _WeightedKeyword('how to get stronger', 1.3), _WeightedKeyword('increase weight', 0.8),
        _WeightedKeyword('add weight', 0.8),
      ],
      _QueryIntent.recovery: [
        _WeightedKeyword('rest day', 1.3), _WeightedKeyword('recovery', 1.3),
        _WeightedKeyword('deload', 1.5), _WeightedKeyword('overtraining', 1.5),
        _WeightedKeyword('how many rest days', 1.5), _WeightedKeyword('when to rest', 1.3),
        _WeightedKeyword('sleep', 0.8), _WeightedKeyword('fatigue', 1.0),
        _WeightedKeyword('soreness', 1.0), _WeightedKeyword('doms', 1.2), _WeightedKeyword('tired', 0.6),
      ],
      _QueryIntent.fatLoss: [
        _WeightedKeyword('lose weight', 1.3), _WeightedKeyword('fat loss', 1.5),
        _WeightedKeyword('weight loss', 1.3), _WeightedKeyword('cutting', 1.3),
        _WeightedKeyword('cut', 0.8), _WeightedKeyword('lean out', 1.2),
        _WeightedKeyword('burn fat', 1.3), _WeightedKeyword('shred', 1.0),
        _WeightedKeyword('body fat', 1.0), _WeightedKeyword('lose fat', 1.3),
      ],
      _QueryIntent.muscleGain: [
        _WeightedKeyword('build muscle', 1.5), _WeightedKeyword('muscle gain', 1.5),
        _WeightedKeyword('bulking', 1.3), _WeightedKeyword('bulk', 0.8),
        _WeightedKeyword('gain weight', 1.0), _WeightedKeyword('hypertrophy', 1.5),
        _WeightedKeyword('grow', 0.6), _WeightedKeyword('mass', 0.8), _WeightedKeyword('lean bulk', 1.3),
      ],
      _QueryIntent.supplements: [
        _WeightedKeyword('supplement', 1.5), _WeightedKeyword('creatine', 1.5),
        _WeightedKeyword('bcaa', 1.3), _WeightedKeyword('pre workout', 1.0),
        _WeightedKeyword('vitamin', 1.0), _WeightedKeyword('fish oil', 1.0),
      ],
      _QueryIntent.volume: [
        _WeightedKeyword('how many sets', 1.5), _WeightedKeyword('how many reps', 1.5),
        _WeightedKeyword('training volume', 1.5), _WeightedKeyword('volume', 1.0),
        _WeightedKeyword('rep range', 1.3), _WeightedKeyword('set range', 1.3),
      ],
      _QueryIntent.hydration: [
        _WeightedKeyword('how much water', 1.5), _WeightedKeyword('hydration', 1.3),
        _WeightedKeyword('water', 0.8), _WeightedKeyword('fluid', 0.8),
      ],
      _QueryIntent.logBodyMetric: [
        _WeightedKeyword('i weigh', 2.0), _WeightedKeyword('my weight is', 2.0),
        _WeightedKeyword('update my weight', 2.0), _WeightedKeyword('log my weight', 2.0),
        _WeightedKeyword('body fat', 1.5), _WeightedKeyword('my bf is', 1.5),
        _WeightedKeyword('body fat is', 1.8), _WeightedKeyword('log body', 1.5),
        _WeightedKeyword('waist is', 1.3), _WeightedKeyword('chest is', 1.3),
        _WeightedKeyword('update weight', 1.8), _WeightedKeyword('new weight', 1.5),
        _WeightedKeyword('weighed in', 1.8), _WeightedKeyword('scale says', 1.8),
        _WeightedKeyword('i\'m at', 1.0),
      ],
      _QueryIntent.viewProgress: [
        _WeightedKeyword('show my progress', 2.0), _WeightedKeyword('my progress', 1.5),
        _WeightedKeyword('how am i doing', 1.5), _WeightedKeyword('how much have i lost', 1.8),
        _WeightedKeyword('how much have i gained', 1.8), _WeightedKeyword('my stats', 1.5),
        _WeightedKeyword('am i on track', 1.5), _WeightedKeyword('weekly summary', 1.5),
        _WeightedKeyword('how many workouts', 1.3), _WeightedKeyword('show my workouts', 1.3),
        _WeightedKeyword('workout history', 1.5), _WeightedKeyword('what did i do', 1.3),
      ],
      _QueryIntent.planWorkout: [
        _WeightedKeyword('what should i train', 2.0), _WeightedKeyword('plan my workout', 2.0),
        _WeightedKeyword('plan today', 1.8), _WeightedKeyword('what to train today', 2.0),
        _WeightedKeyword('suggest a workout', 1.8), _WeightedKeyword('give me a workout', 1.8),
        _WeightedKeyword('what muscle', 1.3), _WeightedKeyword('what body part', 1.3),
        _WeightedKeyword('next workout', 1.3), _WeightedKeyword('today\'s workout', 1.5),
      ],
      _QueryIntent.greeting: [
        _WeightedKeyword('hello', 2.0), _WeightedKeyword('hi', 1.5),
        _WeightedKeyword('hey', 1.5), _WeightedKeyword('good morning', 2.0),
        _WeightedKeyword('good afternoon', 2.0), _WeightedKeyword('good evening', 2.0),
        _WeightedKeyword('what\'s up', 1.5), _WeightedKeyword('sup', 1.3),
        _WeightedKeyword('yo', 1.0), _WeightedKeyword('howdy', 1.3),
      ],
    };

    for (final entry in keywordMap.entries) {
      for (final kw in entry.value) {
        if (input.contains(kw.keyword)) {
          scores[entry.key] = (scores[entry.key] ?? 0) + kw.weight;
        }
      }
    }

    if (_isMealLoggingIntent(input)) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 2.0;
    }
    if (_isWorkoutLoggingIntent(input)) {
      scores[_QueryIntent.logWorkout] = (scores[_QueryIntent.logWorkout] ?? 0) + 2.0;
    }
    if (_isBodyMetricIntent(input)) {
      scores[_QueryIntent.logBodyMetric] = (scores[_QueryIntent.logBodyMetric] ?? 0) + 2.5;
    }
    if (_containsPhrase(input, ['chest', 'bench press', 'back', 'pull up', 'row', 'legs', 'squat', 'deadlift', 'shoulder', 'bicep', 'tricep', 'arm', 'glute', 'hamstring', 'quad'])) {
      scores[_QueryIntent.exerciseSpecific] = (scores[_QueryIntent.exerciseSpecific] ?? 0) + 1.0;
    }
  }

  bool _isBodyMetricIntent(String input) {
    // "I weigh 82 kg", "scale says 80.5", "my weight is 75kg", "body fat is 15%"
    if (RegExp(r'(?:i weigh|weighed in|scale says|my weight is|weight is|new weight)\s+(\d+(?:\.\d+)?)\s*(?:kg|lbs?|lb|pounds?)?', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp(r'(?:body ?fat|bf|body fat percentage)\s*(?:is|at)?\s*(\d+(?:\.\d+)?)\s*%?', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp("(?:i'?m|i am)\\s+(?:at\\s+)?(\\d+(?:\\.\\d+)?)\\s*(?:kg|lbs?)\\b", caseSensitive: false).hasMatch(input)) return true;
    return false;
  }

  void _applyStructureScores(String input, Map<_QueryIntent, double> scores) {
    final isCommand = input.startsWith('log') || input.startsWith('track') || input.startsWith('record') || input.startsWith('save') || input.startsWith('add');
    final isQuestion = input.contains('?') || input.startsWith('how') || input.startsWith('what') || input.startsWith('when') || input.startsWith('should') || input.startsWith('can') || input.startsWith('do') || input.startsWith('is');

    if (isCommand) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 0.5;
      scores[_QueryIntent.logWorkout] = (scores[_QueryIntent.logWorkout] ?? 0) + 0.5;
    }

    // Strong meal logging signals
    if (input.startsWith('i ate') || input.startsWith('i had') || input.startsWith('i just ate') || input.startsWith('i just had') || input.startsWith('i\'m eating') || input.startsWith('i am eating') || input.startsWith('just had') || input.startsWith('just ate')) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 1.5;
    }

    // "for breakfast/lunch/dinner I had..." pattern
    if (RegExp(r'for\s+(?:breakfast|lunch|dinner|snack)\s+(?:i\s+)?(?:had|ate|got)', caseSensitive: false).hasMatch(input)) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 2.0;
    }

    // Implicit food mentions without "log" keyword: "200g chicken", "4 eggs and toast"
    if (RegExp(r'\d+\s*(?:g|grams?|ml|oz)\s+\w+', caseSensitive: false).hasMatch(input)) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 0.8;
    }
    if (RegExp(r'\d+\s+(?:eggs?|toast|slices?|scoops?|cups?|pieces?|servings?)\b', caseSensitive: false).hasMatch(input)) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 1.0;
    }

    if (input.startsWith('i did') || input.startsWith('i trained') || input.startsWith('i worked out') || input.startsWith('just finished')) {
      scores[_QueryIntent.logWorkout] = (scores[_QueryIntent.logWorkout] ?? 0) + 1.0;
    }

    // Greetings: very short messages that are just hi/hello
    if (input.length < 20 && RegExp(r'^(?:hi|hey|hello|yo|sup|good\s+(?:morning|afternoon|evening))[\s!.]*$', caseSensitive: false).hasMatch(input)) {
      scores[_QueryIntent.greeting] = (scores[_QueryIntent.greeting] ?? 0) + 3.0;
    }

    if (isQuestion) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) - 0.3;
      scores[_QueryIntent.logWorkout] = (scores[_QueryIntent.logWorkout] ?? 0) - 0.3;
    }
  }

  void _applyHistoryScores(String input, List<AiMessage> history, Map<_QueryIntent, double> scores) {
    if (history.isEmpty) return;
    final lastAssistant = history.lastWhere((m) => m.role == 'assistant', orElse: () => AiMessage.assistant(''));
    final lastContent = lastAssistant.content.toLowerCase();

    if (lastContent.contains('what did you have') || lastContent.contains('what did you eat') || lastContent.contains('tell me what you') || lastContent.contains('help log it')) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 2.0;
    }
    if (lastContent.contains('what exercises') || lastContent.contains('which exercises') || lastContent.contains('include weights')) {
      scores[_QueryIntent.logWorkout] = (scores[_QueryIntent.logWorkout] ?? 0) + 1.5;
    }
    if (input.length < 30) {
      final lastUser = history.lastWhere((m) => m.role == 'user', orElse: () => AiMessage.user(''));
      if (_isMealLoggingIntent(lastUser.content.toLowerCase())) {
        scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 1.0;
      }
    }
  }

  void _applyAgentBias(AiAgentType agent, Map<_QueryIntent, double> scores) {
    switch (agent) {
      case AiAgentType.nutritionist:
        for (final i in [_QueryIntent.calories, _QueryIntent.protein, _QueryIntent.macros, _QueryIntent.mealTiming, _QueryIntent.logMeal, _QueryIntent.supplements, _QueryIntent.hydration]) {
          scores[i] = (scores[i] ?? 0) + 0.3;
        }
      case AiAgentType.trainer:
        for (final i in [_QueryIntent.workoutSplit, _QueryIntent.progressiveOverload, _QueryIntent.recovery, _QueryIntent.volume, _QueryIntent.exerciseSpecific, _QueryIntent.logWorkout]) {
          scores[i] = (scores[i] ?? 0) + 0.3;
        }
      case AiAgentType.general:
        break;
    }
  }

  void _applyEntityScores(String input, Map<_QueryIntent, double> scores, Map<String, dynamic> extractedData) {
    final foodEntities = _extractFoodEntities(input);
    if (foodEntities.isNotEmpty) {
      scores[_QueryIntent.logMeal] = (scores[_QueryIntent.logMeal] ?? 0) + 1.0;
      extractedData['foods'] = foodEntities;
    }
    final exercisePattern = RegExp(r'(\w[\w\s]+?)\s+(\d+)\s*(?:kg|lbs?)\s*(?:(\d+)\s*[x×]\s*(\d+))?', caseSensitive: false);
    final setsRepsFirst = RegExp(r'(\d+)\s*[x×]\s*(\d+)\s+(\w[\w\s]+?)\s+(?:at\s+)?(\d+)\s*(?:kg|lbs?)', caseSensitive: false);
    if (exercisePattern.hasMatch(input) || setsRepsFirst.hasMatch(input)) {
      scores[_QueryIntent.logWorkout] = (scores[_QueryIntent.logWorkout] ?? 0) + 1.5;
    }
  }

  List<String> _extractFoodEntities(String input) {
    final found = <String>[];
    const commonFoods = ['chicken breast', 'chicken', 'rice', 'eggs', 'egg', 'protein shake', 'oats', 'banana', 'bread', 'toast', 'steak', 'salmon', 'pasta', 'yogurt', 'avocado', 'sweet potato', 'broccoli', 'tuna', 'beef', 'peanut butter', 'milk', 'cheese', 'apple', 'almonds', 'turkey'];
    for (final food in commonFoods) {
      if (input.contains(food)) found.add(food);
    }
    return found;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Decision engine
  // ═══════════════════════════════════════════════════════════════════════════

  _AgentDecision _decideAction(_IntentResult result, _UserContext profile) {
    if (result.intent == _QueryIntent.greeting) return _AgentDecision.informOnly;
    if (result.intent == _QueryIntent.general && result.confidence < 0.3) return _AgentDecision.informOnly;
    if (result.intent == _QueryIntent.logMeal || result.intent == _QueryIntent.logWorkout) {
      if (result.confidence >= 0.6 && result.extractedData.isNotEmpty) return _AgentDecision.autoAct;
      if (result.confidence >= 0.4) return _AgentDecision.confirmFirst;
      if (result.clarificationNeeded != null) return _AgentDecision.askClarification;
    }
    if (result.intent == _QueryIntent.logBodyMetric) {
      if (result.confidence >= 0.5) return _AgentDecision.autoAct;
      return _AgentDecision.askClarification;
    }
    return _AgentDecision.informOnly;
  }

  AiChatResponse _buildClarificationResponse(_IntentResult result, _UserContext profile) {
    final namePrefix = profile.name != null && profile.name!.isNotEmpty ? '${profile.name}, ' : '';
    if (result.intent == _QueryIntent.logMeal) {
      return AiChatResponse(
        message: '${namePrefix}I\'d love to help log that meal! What did you have? Include quantities if you can — for example, "4 eggs and 2 toast" or "200g chicken with rice".',
        suggestions: ['I had eggs for breakfast', 'Chicken and rice for lunch', 'Just a protein shake'],
      );
    }
    if (result.intent == _QueryIntent.logWorkout) {
      return AiChatResponse(
        message: '${namePrefix}I can log that workout for you! What exercises did you do? Include weights if possible.\n\nFor example:\n- "bench 80kg 3x10"\n- "squats 100kg 5x5"\n- Or list them with weights and I\'ll use default sets/reps.',
        suggestions: ['Bench press 80kg 3x10', 'Show me the format', 'Log today\'s leg day'],
      );
    }
    return AiChatResponse(
      message: result.clarificationNeeded ?? 'Could you tell me more about what you\'re looking for?',
      suggestions: ['How many calories do I need?', 'Log a meal', 'Recommend a workout split'],
    );
  }

  AiChatResponse _buildProactiveResponse(_UserContext profile, Map<String, dynamic>? context) {
    final insights = generateInsights(context ?? {});
    if (insights.isEmpty) return _defaultGeneralResponse(profile);
    return AiChatResponse(message: insights.first, suggestions: ['Log a meal', 'What should I eat?', 'How\'s my progress?']);
  }

  AiChatResponse _defaultGeneralResponse(_UserContext ctx) {
    return AiChatResponse(
      message: 'I can help with nutrition (calories, macros, meal timing) and training (splits, volume, progressive overload, recovery). Ask me something specific, or try one of the suggestions below.',
      suggestions: ['How many calories do I need?', 'Recommend a workout split', 'How much protein do I need?', 'When should I deload?'],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Profile extraction
  // ═══════════════════════════════════════════════════════════════════════════

  _UserContext _extractProfile(Map<String, dynamic>? context) {
    if (context == null) return _UserContext.defaults();
    final weight = (context['weight'] as num?)?.toDouble() ?? 75.0;
    final height = (context['height'] as num?)?.toDouble() ?? 175.0;
    final age = context['age'] as int? ?? 25;
    final goalStr = context['goal'] as String? ?? 'generalFitness';
    final levelStr = context['level'] as String? ?? 'intermediate';
    final calorieTarget = (context['dailyCalorieTarget'] as num?)?.toDouble() ?? 2200.0;
    final proteinTarget = (context['proteinTarget'] as num?)?.toDouble() ?? 150.0;
    final carbsTarget = (context['carbsTarget'] as num?)?.toDouble() ?? 250.0;
    final fatsTarget = (context['fatsTarget'] as num?)?.toDouble() ?? 70.0;
    final workoutDays = context['workoutDaysPerWeek'] as int? ?? 4;
    final name = context['name'] as String?;

    WorkoutGoal goal;
    try { goal = WorkoutGoal.values.byName(goalStr); } catch (_) { goal = WorkoutGoal.generalFitness; }
    ExperienceLevel level;
    try { level = ExperienceLevel.values.byName(levelStr); } catch (_) { level = ExperienceLevel.intermediate; }

    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    double activityMultiplier;
    if (workoutDays <= 1) { activityMultiplier = 1.2; }
    else if (workoutDays <= 3) { activityMultiplier = 1.375; }
    else if (workoutDays <= 5) { activityMultiplier = 1.55; }
    else { activityMultiplier = 1.725; }
    final tdee = bmr * activityMultiplier;

    double proteinPerKg;
    switch (goal) {
      case WorkoutGoal.fatLoss: proteinPerKg = 2.2;
      case WorkoutGoal.hypertrophy: proteinPerKg = 2.0;
      case WorkoutGoal.strength: proteinPerKg = 2.0;
      case WorkoutGoal.generalFitness: proteinPerKg = 1.8;
      case WorkoutGoal.endurance: proteinPerKg = 1.6;
    }

    return _UserContext(name: name, weight: weight, height: height, age: age, goal: goal, level: level, bmr: bmr, tdee: tdee, calorieTarget: calorieTarget, proteinTarget: proteinTarget, carbsTarget: carbsTarget, fatsTarget: fatsTarget, proteinPerKg: proteinPerKg, workoutDays: workoutDays);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Intent detection helpers
  // ═══════════════════════════════════════════════════════════════════════════

  bool _containsPhrase(String input, List<String> phrases) => phrases.any((p) => input.contains(p));

  bool _isWorkoutLoggingIntent(String input) {
    if (_containsPhrase(input, ['log these', 'log my', 'log the', 'log workout', 'log this workout', 'record my', 'record these', 'record workout', 'track my workout', 'track these', 'save my workout', 'save these workout', 'add my workout', 'add these workout', 'i did these', 'i did this workout', 'i completed', 'here is my workout', 'here are my workout', "here's my workout"])) return true;
    final exerciseWeightPattern = RegExp(r'[a-zA-Z][\w\s]+[:\-]\s*\d+\s*(?:kg|lbs?|lb)', caseSensitive: false);
    final matches = exerciseWeightPattern.allMatches(input).length;
    if (matches >= 2) return true;
    if (RegExp(r'\b\w+\s+\d+\s*kg\s+\d+\s*[x×]\s*\d+', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp(r'\d+\s*[x×]\s*\d+\s+\w+\s+(?:at\s+)?\d+', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp(r'\d+\s+sets?\s+(?:of\s+)?\w+.*?\d+\s*(?:kg|lbs?)', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp(r'(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|day\s*\d|week\s*\d)', caseSensitive: false).hasMatch(input) && matches >= 1) return true;
    return false;
  }

  bool _isMealLoggingIntent(String input) {
    if (_containsPhrase(input, ['log my meal', 'log this meal', 'log my food', 'log what i ate', 'log what i had', 'track my meal', 'track what i ate', 'record my meal', 'save my meal', 'add my meal', 'i just ate', 'i just had', 'i ate', 'i had for breakfast', 'i had for lunch', 'i had for dinner', 'for breakfast i had', 'for lunch i had', 'for dinner i had', 'log breakfast', 'log lunch', 'log dinner', 'log snack', 'i\'m eating', 'i am eating', 'just ate', 'just had', 'had some', 'ate some', 'i\'ve had', 'i\'ve eaten'])) return true;
    // Implicit food: message contains recognizable food items with quantities
    if (RegExp(r'\d+\s*(?:g|grams?|eggs?|slices?|scoops?|cups?|pieces?)\s+\w+', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp(r'\d+\s+(?:chicken|eggs?|toast|rice|oats|banana|protein|steak|salmon|tuna|pasta|bread)', caseSensitive: false).hasMatch(input)) return true;
    // Common food items mentioned directly
    if (_containsPhrase(input, ['protein shake', 'chicken and rice', 'eggs and toast'])) return true;
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Meal logging
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handleMealLogging(String message, _UserContext ctx, {Map<String, dynamic>? context}) {
    final foods = _parseMealText(message);
    if (foods.isEmpty) {
      final namePrefix = ctx.name != null && ctx.name!.isNotEmpty ? '${ctx.name}, ' : '';
      return AiChatResponse(
        message: '${namePrefix}I can help you log that meal! Could you give me a bit more detail?\n\nTry something like:\n- "I had 4 boiled eggs for breakfast"\n- "200g chicken breast and rice for lunch"\n- "protein shake with a banana"\n\nI\'ll estimate the nutrition and log it for you.',
        suggestions: ['Log a quick meal', 'What should I eat next?', 'How many calories left today?'],
      );
    }

    final actions = <AiAction>[];
    final foodDescriptions = <String>[];
    for (final food in foods) {
      actions.add(AiAction(type: 'log_meal', label: 'Log ${food.name}', data: {'name': food.name, 'calories': food.calories, 'protein': food.protein, 'carbs': food.carbs, 'fats': food.fats, 'fiber': 0.0, 'meal_type': food.mealType, 'serving_size': food.servingSize, 'serving_unit': food.servingUnit}));
      foodDescriptions.add('• **${food.name}** (${food.servingSize.round()}${food.servingUnit}) — ${food.calories.round()} kcal, ${food.protein.round()}g P, ${food.carbs.round()}g C, ${food.fats.round()}g F');
    }

    final totalCal = foods.fold<double>(0, (s, f) => s + f.calories);
    final totalPro = foods.fold<double>(0, (s, f) => s + f.protein);
    String followUp = '';
    if (context != null) {
      final todayCal = (context['todayCalories'] as num?)?.toDouble() ?? 0;
      final remaining = ctx.calorieTarget - todayCal - totalCal;
      if (remaining > 0) {
        followUp = '\n\nYou\'ll have ~${remaining.round()} kcal remaining for the rest of the day.';
      } else if (remaining < -100) {
        followUp = '\n\nHeads up — this puts you about ${remaining.abs().round()} kcal over your daily target.';
      }
    }

    return AiChatResponse(
      message: 'Logging ${foods.length} item${foods.length > 1 ? 's' : ''} for ${foods.first.mealType}:\n\n${foodDescriptions.join('\n')}\n\n**Total:** ${totalCal.round()} kcal, ${totalPro.round()}g protein$followUp',
      suggestions: ['What else should I eat today?', 'Am I on track for my macros?', 'Log another meal'],
      actions: actions,
    );
  }

  String _classifyMealType(String input) {
    if (input.contains('breakfast') || input.contains('morning meal') || input.contains('for breakfast')) return 'breakfast';
    if (input.contains('lunch') || input.contains('midday') || input.contains('for lunch')) return 'lunch';
    if (input.contains('dinner') || input.contains('supper') || input.contains('evening meal') || input.contains('for dinner')) return 'dinner';
    if (input.contains('snack') || input.contains('pre workout') || input.contains('post workout') || input.contains('after gym') || input.contains('before gym') || input.contains('pre-workout') || input.contains('post-workout') || input.contains('between meals')) return 'snack';
    // Infer from typical foods
    if (input.contains('oats') || input.contains('oatmeal') || input.contains('cereal') || input.contains('pancake') || input.contains('waffle') || input.contains('french toast')) return 'breakfast';
    if (input.contains('protein shake') || input.contains('protein bar') || input.contains('granola bar')) return 'snack';
    // Time-based fallback
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 17) return 'snack';
    if (hour >= 17 && hour < 22) return 'dinner';
    return 'snack';
  }

  List<_ParsedFood> _parseMealText(String message) {
    final foods = <_ParsedFood>[];
    // Strip logging keywords to get just the food description
    final cleaned = message.toLowerCase()
        .replaceAll(RegExp(r'^(?:log|track|record|save|add)\s+(?:my\s+)?(?:meal|food|what i (?:ate|had)|breakfast|lunch|dinner|snack)\s*:?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:i\s+)?(?:just\s+)?(?:ate|had|eaten|eating)\s*:?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:for\s+)?(?:breakfast|lunch|dinner|snack)\s+(?:i\s+)?(?:had|ate|got)\s*:?\s*', caseSensitive: false), '')
        .trim();
    final lower = cleaned.isEmpty ? message.toLowerCase() : cleaned;
    final mealType = _classifyMealType(message.toLowerCase());

    // First try matching against the FoodDatabaseService (65+ curated items)
    final dbFoods = _foodDb.searchFoods('');
    final matchedDbNames = <String>{};

    // Sort by name length descending to match longer names first
    final sortedDbFoods = List.of(dbFoods)..sort((a, b) => b.name.length.compareTo(a.name.length));

    for (final dbFood in sortedDbFoods) {
      final foodNameLower = dbFood.name.toLowerCase();
      // Skip if a longer match already covers this food
      if (matchedDbNames.any((m) => m.contains(foodNameLower) || foodNameLower.contains(m))) continue;

      if (lower.contains(foodNameLower)) {
        double servingMultiplier = 1.0;

        // Try gram-based quantity
        final qtyPattern = RegExp('(\\d+(?:\\.\\d+)?)\\s*(?:g|grams?|gr)\\s*(?:of\\s+)?${RegExp.escape(foodNameLower)}', caseSensitive: false);
        final qtyMatch = qtyPattern.firstMatch(lower);
        if (qtyMatch != null) {
          final qty = double.parse(qtyMatch.group(1)!);
          servingMultiplier = qty / (dbFood.servingSize > 0 ? dbFood.servingSize : 100);
        } else {
          // Try count-based: "4 eggs", "2 whole eggs"
          final countPattern = RegExp('(\\d+)\\s+(?:boiled\\s+|fried\\s+|scrambled\\s+|poached\\s+|grilled\\s+|baked\\s+)?${RegExp.escape(foodNameLower)}', caseSensitive: false);
          final countMatch = countPattern.firstMatch(lower);
          if (countMatch != null) {
            servingMultiplier = double.parse(countMatch.group(1)!);
          }
        }

        foods.add(_ParsedFood(
          name: dbFood.name,
          calories: dbFood.calories * servingMultiplier,
          protein: dbFood.protein * servingMultiplier,
          carbs: dbFood.carbs * servingMultiplier,
          fats: dbFood.fats * servingMultiplier,
          servingSize: dbFood.servingSize * servingMultiplier,
          servingUnit: dbFood.servingUnit,
          mealType: mealType,
        ));
        matchedDbNames.add(foodNameLower);
      }
    }

    // Fall back to the expanded common foods estimator for anything not matched
    if (foods.isEmpty) {
      foods.addAll(_estimateCommonFoods(lower, mealType));
    } else {
      // Also check for additional foods not in the DB match
      // e.g., user said "chicken breast and toast" - chicken matched from DB, toast might not
      final remainingText = lower;
      final extraFoods = _estimateCommonFoods(remainingText, mealType);
      for (final extra in extraFoods) {
        // Only add if not already matched from the DB
        if (!foods.any((f) => f.name.toLowerCase() == extra.name.toLowerCase())) {
          foods.add(extra);
        }
      }
    }

    return foods;
  }

  List<_ParsedFood> _estimateCommonFoods(String input, String mealType) {
    final foods = <_ParsedFood>[];
    // ── 120+ common foods with accurate nutrition data (per serving) ─────────
    final estimates = <String, _ParsedFood>{
      // Proteins
      'chicken breast': _ParsedFood(name: 'Chicken Breast', calories: 165, protein: 31, carbs: 0, fats: 3.6, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'grilled chicken': _ParsedFood(name: 'Grilled Chicken', calories: 165, protein: 31, carbs: 0, fats: 3.6, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'chicken thigh': _ParsedFood(name: 'Chicken Thigh', calories: 209, protein: 26, carbs: 0, fats: 11, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'chicken': _ParsedFood(name: 'Chicken', calories: 165, protein: 31, carbs: 0, fats: 3.6, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'ground beef': _ParsedFood(name: 'Ground Beef (90% lean)', calories: 176, protein: 20, carbs: 0, fats: 10, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'beef': _ParsedFood(name: 'Beef', calories: 250, protein: 26, carbs: 0, fats: 15, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'steak': _ParsedFood(name: 'Steak', calories: 271, protein: 26, carbs: 0, fats: 18, servingSize: 150, servingUnit: 'g', mealType: mealType),
      'salmon': _ParsedFood(name: 'Salmon', calories: 208, protein: 20, carbs: 0, fats: 13, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'tuna': _ParsedFood(name: 'Tuna', calories: 132, protein: 28, carbs: 0, fats: 1.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'shrimp': _ParsedFood(name: 'Shrimp', calories: 99, protein: 24, carbs: 0.2, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'turkey breast': _ParsedFood(name: 'Turkey Breast', calories: 135, protein: 30, carbs: 0, fats: 1, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'turkey': _ParsedFood(name: 'Turkey', calories: 135, protein: 30, carbs: 0, fats: 1, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'tofu': _ParsedFood(name: 'Tofu', calories: 144, protein: 17, carbs: 3, fats: 9, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'lamb': _ParsedFood(name: 'Lamb', calories: 282, protein: 25, carbs: 0, fats: 20, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'pork': _ParsedFood(name: 'Pork', calories: 242, protein: 27, carbs: 0, fats: 14, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'pork chop': _ParsedFood(name: 'Pork Chop', calories: 231, protein: 26, carbs: 0, fats: 13, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'fish': _ParsedFood(name: 'White Fish', calories: 105, protein: 23, carbs: 0, fats: 1, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'cod': _ParsedFood(name: 'Cod', calories: 82, protein: 18, carbs: 0, fats: 0.7, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'tilapia': _ParsedFood(name: 'Tilapia', calories: 96, protein: 20, carbs: 0, fats: 1.7, servingSize: 100, servingUnit: 'g', mealType: mealType),
      // Eggs (per egg)
      'boiled eggs': _ParsedFood(name: 'Boiled Egg', calories: 78, protein: 6.3, carbs: 0.6, fats: 5.3, servingSize: 1, servingUnit: 'egg', mealType: mealType),
      'boiled egg': _ParsedFood(name: 'Boiled Egg', calories: 78, protein: 6.3, carbs: 0.6, fats: 5.3, servingSize: 1, servingUnit: 'egg', mealType: mealType),
      'fried eggs': _ParsedFood(name: 'Fried Egg', calories: 90, protein: 6.3, carbs: 0.6, fats: 7, servingSize: 1, servingUnit: 'egg', mealType: mealType),
      'fried egg': _ParsedFood(name: 'Fried Egg', calories: 90, protein: 6.3, carbs: 0.6, fats: 7, servingSize: 1, servingUnit: 'egg', mealType: mealType),
      'scrambled eggs': _ParsedFood(name: 'Scrambled Eggs', calories: 91, protein: 6.1, carbs: 1, fats: 6.7, servingSize: 1, servingUnit: 'egg', mealType: mealType),
      'omelette': _ParsedFood(name: 'Omelette (3 eggs)', calories: 270, protein: 19, carbs: 2, fats: 21, servingSize: 1, servingUnit: 'serving', mealType: mealType),
      'eggs': _ParsedFood(name: 'Egg', calories: 78, protein: 6.3, carbs: 0.6, fats: 5.3, servingSize: 1, servingUnit: 'egg', mealType: mealType),
      'egg': _ParsedFood(name: 'Egg', calories: 78, protein: 6.3, carbs: 0.6, fats: 5.3, servingSize: 1, servingUnit: 'egg', mealType: mealType),
      'egg whites': _ParsedFood(name: 'Egg Whites', calories: 17, protein: 3.6, carbs: 0.2, fats: 0.1, servingSize: 1, servingUnit: 'egg white', mealType: mealType),
      // Dairy
      'greek yogurt': _ParsedFood(name: 'Greek Yogurt', calories: 59, protein: 10, carbs: 3.6, fats: 0.7, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'yogurt': _ParsedFood(name: 'Yogurt', calories: 59, protein: 10, carbs: 3.6, fats: 0.7, servingSize: 150, servingUnit: 'g', mealType: mealType),
      'cottage cheese': _ParsedFood(name: 'Cottage Cheese', calories: 98, protein: 11, carbs: 3.4, fats: 4.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'cheese': _ParsedFood(name: 'Cheese', calories: 113, protein: 7, carbs: 0.4, fats: 9.3, servingSize: 30, servingUnit: 'g', mealType: mealType),
      'mozzarella': _ParsedFood(name: 'Mozzarella', calories: 280, protein: 28, carbs: 3, fats: 17, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'milk': _ParsedFood(name: 'Milk', calories: 149, protein: 8, carbs: 12, fats: 8, servingSize: 240, servingUnit: 'ml', mealType: mealType),
      'skim milk': _ParsedFood(name: 'Skim Milk', calories: 83, protein: 8.3, carbs: 12, fats: 0.2, servingSize: 240, servingUnit: 'ml', mealType: mealType),
      'cream cheese': _ParsedFood(name: 'Cream Cheese', calories: 99, protein: 1.7, carbs: 1.6, fats: 10, servingSize: 28, servingUnit: 'g', mealType: mealType),
      // Grains & Carbs
      'white rice': _ParsedFood(name: 'White Rice (cooked)', calories: 130, protein: 2.7, carbs: 28, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'brown rice': _ParsedFood(name: 'Brown Rice (cooked)', calories: 123, protein: 2.7, carbs: 26, fats: 1, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'rice': _ParsedFood(name: 'Rice (cooked)', calories: 130, protein: 2.7, carbs: 28, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'pasta': _ParsedFood(name: 'Pasta (cooked)', calories: 157, protein: 5.8, carbs: 31, fats: 0.9, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'spaghetti': _ParsedFood(name: 'Spaghetti (cooked)', calories: 157, protein: 5.8, carbs: 31, fats: 0.9, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'noodles': _ParsedFood(name: 'Noodles (cooked)', calories: 138, protein: 4.5, carbs: 25, fats: 2.1, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'oats': _ParsedFood(name: 'Oats (dry)', calories: 150, protein: 5, carbs: 27, fats: 3, servingSize: 40, servingUnit: 'g', mealType: mealType),
      'oatmeal': _ParsedFood(name: 'Oatmeal', calories: 150, protein: 5, carbs: 27, fats: 3, servingSize: 40, servingUnit: 'g', mealType: mealType),
      'porridge': _ParsedFood(name: 'Porridge', calories: 150, protein: 5, carbs: 27, fats: 3, servingSize: 40, servingUnit: 'g', mealType: mealType),
      'bread': _ParsedFood(name: 'Bread', calories: 80, protein: 3, carbs: 15, fats: 1, servingSize: 1, servingUnit: 'slice', mealType: mealType),
      'toast': _ParsedFood(name: 'Toast', calories: 80, protein: 3, carbs: 15, fats: 1, servingSize: 1, servingUnit: 'slice', mealType: mealType),
      'whole wheat bread': _ParsedFood(name: 'Whole Wheat Bread', calories: 82, protein: 4, carbs: 14, fats: 1.1, servingSize: 1, servingUnit: 'slice', mealType: mealType),
      'bagel': _ParsedFood(name: 'Bagel', calories: 245, protein: 10, carbs: 48, fats: 1.5, servingSize: 1, servingUnit: 'bagel', mealType: mealType),
      'tortilla': _ParsedFood(name: 'Tortilla', calories: 120, protein: 3, carbs: 20, fats: 3, servingSize: 1, servingUnit: 'tortilla', mealType: mealType),
      'potato': _ParsedFood(name: 'Potato (baked)', calories: 161, protein: 4.3, carbs: 37, fats: 0.2, servingSize: 173, servingUnit: 'g', mealType: mealType),
      'sweet potato': _ParsedFood(name: 'Sweet Potato', calories: 103, protein: 2.3, carbs: 24, fats: 0.1, servingSize: 114, servingUnit: 'g', mealType: mealType),
      'quinoa': _ParsedFood(name: 'Quinoa (cooked)', calories: 120, protein: 4.4, carbs: 21, fats: 1.9, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'couscous': _ParsedFood(name: 'Couscous (cooked)', calories: 112, protein: 3.8, carbs: 23, fats: 0.2, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'cereal': _ParsedFood(name: 'Cereal', calories: 150, protein: 3, carbs: 33, fats: 1, servingSize: 40, servingUnit: 'g', mealType: mealType),
      'granola': _ParsedFood(name: 'Granola', calories: 210, protein: 5, carbs: 29, fats: 9, servingSize: 45, servingUnit: 'g', mealType: mealType),
      'pancakes': _ParsedFood(name: 'Pancakes', calories: 227, protein: 6.4, carbs: 28, fats: 10, servingSize: 2, servingUnit: 'pancakes', mealType: mealType),
      'waffles': _ParsedFood(name: 'Waffles', calories: 218, protein: 5.9, carbs: 25, fats: 11, servingSize: 1, servingUnit: 'waffle', mealType: mealType),
      'french toast': _ParsedFood(name: 'French Toast', calories: 149, protein: 5, carbs: 16, fats: 7, servingSize: 1, servingUnit: 'slice', mealType: mealType),
      // Fruits (per medium fruit or 100g)
      'banana': _ParsedFood(name: 'Banana', calories: 105, protein: 1.3, carbs: 27, fats: 0.4, servingSize: 1, servingUnit: 'banana', mealType: mealType),
      'apple': _ParsedFood(name: 'Apple', calories: 95, protein: 0.5, carbs: 25, fats: 0.3, servingSize: 1, servingUnit: 'apple', mealType: mealType),
      'orange': _ParsedFood(name: 'Orange', calories: 62, protein: 1.2, carbs: 15, fats: 0.2, servingSize: 1, servingUnit: 'orange', mealType: mealType),
      'berries': _ParsedFood(name: 'Mixed Berries', calories: 57, protein: 0.7, carbs: 14, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'blueberries': _ParsedFood(name: 'Blueberries', calories: 57, protein: 0.7, carbs: 14, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'strawberries': _ParsedFood(name: 'Strawberries', calories: 32, protein: 0.7, carbs: 8, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'grapes': _ParsedFood(name: 'Grapes', calories: 69, protein: 0.7, carbs: 18, fats: 0.2, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'mango': _ParsedFood(name: 'Mango', calories: 99, protein: 1.4, carbs: 25, fats: 0.6, servingSize: 1, servingUnit: 'cup', mealType: mealType),
      'avocado': _ParsedFood(name: 'Avocado', calories: 240, protein: 3, carbs: 13, fats: 22, servingSize: 1, servingUnit: 'avocado', mealType: mealType),
      'dates': _ParsedFood(name: 'Dates', calories: 66, protein: 0.4, carbs: 18, fats: 0, servingSize: 1, servingUnit: 'date', mealType: mealType),
      'watermelon': _ParsedFood(name: 'Watermelon', calories: 46, protein: 0.9, carbs: 12, fats: 0.2, servingSize: 150, servingUnit: 'g', mealType: mealType),
      'pineapple': _ParsedFood(name: 'Pineapple', calories: 82, protein: 0.9, carbs: 22, fats: 0.2, servingSize: 165, servingUnit: 'g', mealType: mealType),
      // Vegetables
      'broccoli': _ParsedFood(name: 'Broccoli', calories: 34, protein: 2.8, carbs: 7, fats: 0.4, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'spinach': _ParsedFood(name: 'Spinach', calories: 23, protein: 2.9, carbs: 3.6, fats: 0.4, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'salad': _ParsedFood(name: 'Mixed Salad', calories: 20, protein: 1.5, carbs: 3, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'green salad': _ParsedFood(name: 'Green Salad', calories: 20, protein: 1.5, carbs: 3, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'vegetables': _ParsedFood(name: 'Mixed Vegetables', calories: 65, protein: 2.6, carbs: 13, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'veggies': _ParsedFood(name: 'Mixed Vegetables', calories: 65, protein: 2.6, carbs: 13, fats: 0.3, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'corn': _ParsedFood(name: 'Corn', calories: 96, protein: 3.4, carbs: 21, fats: 1.5, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'peas': _ParsedFood(name: 'Green Peas', calories: 81, protein: 5.4, carbs: 14, fats: 0.4, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'beans': _ParsedFood(name: 'Beans', calories: 127, protein: 8.7, carbs: 23, fats: 0.5, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'lentils': _ParsedFood(name: 'Lentils (cooked)', calories: 116, protein: 9, carbs: 20, fats: 0.4, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'chickpeas': _ParsedFood(name: 'Chickpeas', calories: 164, protein: 8.9, carbs: 27, fats: 2.6, servingSize: 100, servingUnit: 'g', mealType: mealType),
      'hummus': _ParsedFood(name: 'Hummus', calories: 166, protein: 7.9, carbs: 14, fats: 10, servingSize: 100, servingUnit: 'g', mealType: mealType),
      // Fats & Nuts
      'peanut butter': _ParsedFood(name: 'Peanut Butter', calories: 94, protein: 4, carbs: 3, fats: 8, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      'almond butter': _ParsedFood(name: 'Almond Butter', calories: 98, protein: 3.4, carbs: 3, fats: 9, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      'almonds': _ParsedFood(name: 'Almonds', calories: 164, protein: 6, carbs: 6, fats: 14, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'walnuts': _ParsedFood(name: 'Walnuts', calories: 185, protein: 4.3, carbs: 4, fats: 18.5, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'cashews': _ParsedFood(name: 'Cashews', calories: 157, protein: 5.2, carbs: 8.6, fats: 12.4, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'peanuts': _ParsedFood(name: 'Peanuts', calories: 161, protein: 7.3, carbs: 4.6, fats: 14, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'nuts': _ParsedFood(name: 'Mixed Nuts', calories: 172, protein: 5, carbs: 6, fats: 15, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'olive oil': _ParsedFood(name: 'Olive Oil', calories: 119, protein: 0, carbs: 0, fats: 13.5, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      'butter': _ParsedFood(name: 'Butter', calories: 102, protein: 0.1, carbs: 0, fats: 11.5, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      // Supplements & Shakes
      'protein shake': _ParsedFood(name: 'Protein Shake', calories: 160, protein: 30, carbs: 5, fats: 2.5, servingSize: 1, servingUnit: 'shake', mealType: mealType),
      'protein powder': _ParsedFood(name: 'Protein Powder', calories: 120, protein: 24, carbs: 3, fats: 1.5, servingSize: 1, servingUnit: 'scoop', mealType: mealType),
      'whey': _ParsedFood(name: 'Whey Protein', calories: 120, protein: 24, carbs: 3, fats: 1.5, servingSize: 1, servingUnit: 'scoop', mealType: mealType),
      'whey protein': _ParsedFood(name: 'Whey Protein', calories: 120, protein: 24, carbs: 3, fats: 1.5, servingSize: 1, servingUnit: 'scoop', mealType: mealType),
      'casein': _ParsedFood(name: 'Casein Protein', calories: 120, protein: 24, carbs: 3, fats: 1, servingSize: 1, servingUnit: 'scoop', mealType: mealType),
      'mass gainer': _ParsedFood(name: 'Mass Gainer', calories: 650, protein: 50, carbs: 85, fats: 10, servingSize: 1, servingUnit: 'serving', mealType: mealType),
      'creatine': _ParsedFood(name: 'Creatine', calories: 0, protein: 0, carbs: 0, fats: 0, servingSize: 5, servingUnit: 'g', mealType: mealType),
      'bcaa': _ParsedFood(name: 'BCAA', calories: 15, protein: 3, carbs: 0, fats: 0, servingSize: 1, servingUnit: 'scoop', mealType: mealType),
      // Beverages
      'coffee': _ParsedFood(name: 'Coffee (black)', calories: 2, protein: 0.3, carbs: 0, fats: 0, servingSize: 1, servingUnit: 'cup', mealType: mealType),
      'latte': _ParsedFood(name: 'Latte', calories: 190, protein: 10, carbs: 18, fats: 7, servingSize: 1, servingUnit: 'cup', mealType: mealType),
      'cappuccino': _ParsedFood(name: 'Cappuccino', calories: 120, protein: 8, carbs: 12, fats: 4, servingSize: 1, servingUnit: 'cup', mealType: mealType),
      'orange juice': _ParsedFood(name: 'Orange Juice', calories: 112, protein: 1.7, carbs: 26, fats: 0.5, servingSize: 240, servingUnit: 'ml', mealType: mealType),
      'smoothie': _ParsedFood(name: 'Fruit Smoothie', calories: 200, protein: 5, carbs: 40, fats: 2, servingSize: 1, servingUnit: 'glass', mealType: mealType),
      'green tea': _ParsedFood(name: 'Green Tea', calories: 2, protein: 0, carbs: 0, fats: 0, servingSize: 1, servingUnit: 'cup', mealType: mealType),
      'coconut water': _ParsedFood(name: 'Coconut Water', calories: 46, protein: 1.7, carbs: 9, fats: 0.5, servingSize: 240, servingUnit: 'ml', mealType: mealType),
      // Snacks & Bars
      'protein bar': _ParsedFood(name: 'Protein Bar', calories: 230, protein: 20, carbs: 25, fats: 8, servingSize: 1, servingUnit: 'bar', mealType: mealType),
      'granola bar': _ParsedFood(name: 'Granola Bar', calories: 190, protein: 3, carbs: 29, fats: 7, servingSize: 1, servingUnit: 'bar', mealType: mealType),
      'dark chocolate': _ParsedFood(name: 'Dark Chocolate', calories: 170, protein: 2.2, carbs: 13, fats: 12, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'chocolate': _ParsedFood(name: 'Chocolate', calories: 155, protein: 2, carbs: 17, fats: 9, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'rice cakes': _ParsedFood(name: 'Rice Cakes', calories: 35, protein: 0.7, carbs: 7.3, fats: 0.3, servingSize: 1, servingUnit: 'cake', mealType: mealType),
      'trail mix': _ParsedFood(name: 'Trail Mix', calories: 140, protein: 4, carbs: 13, fats: 9, servingSize: 30, servingUnit: 'g', mealType: mealType),
      'popcorn': _ParsedFood(name: 'Popcorn', calories: 93, protein: 3, carbs: 19, fats: 1, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'chips': _ParsedFood(name: 'Chips', calories: 152, protein: 2, carbs: 15, fats: 10, servingSize: 28, servingUnit: 'g', mealType: mealType),
      'crackers': _ParsedFood(name: 'Crackers', calories: 127, protein: 2.6, carbs: 19, fats: 5, servingSize: 28, servingUnit: 'g', mealType: mealType),
      // Common Meals
      'chicken and rice': _ParsedFood(name: 'Chicken & Rice', calories: 400, protein: 35, carbs: 45, fats: 8, servingSize: 1, servingUnit: 'plate', mealType: mealType),
      'chicken rice': _ParsedFood(name: 'Chicken & Rice', calories: 400, protein: 35, carbs: 45, fats: 8, servingSize: 1, servingUnit: 'plate', mealType: mealType),
      'steak and rice': _ParsedFood(name: 'Steak & Rice', calories: 550, protein: 38, carbs: 48, fats: 20, servingSize: 1, servingUnit: 'plate', mealType: mealType),
      'burger': _ParsedFood(name: 'Burger', calories: 540, protein: 25, carbs: 40, fats: 30, servingSize: 1, servingUnit: 'burger', mealType: mealType),
      'pizza': _ParsedFood(name: 'Pizza (1 slice)', calories: 285, protein: 12, carbs: 36, fats: 10, servingSize: 1, servingUnit: 'slice', mealType: mealType),
      'sandwich': _ParsedFood(name: 'Sandwich', calories: 350, protein: 20, carbs: 35, fats: 14, servingSize: 1, servingUnit: 'sandwich', mealType: mealType),
      'wrap': _ParsedFood(name: 'Wrap', calories: 360, protein: 22, carbs: 35, fats: 14, servingSize: 1, servingUnit: 'wrap', mealType: mealType),
      'burrito': _ParsedFood(name: 'Burrito', calories: 600, protein: 28, carbs: 60, fats: 25, servingSize: 1, servingUnit: 'burrito', mealType: mealType),
      'sushi': _ParsedFood(name: 'Sushi Roll', calories: 255, protein: 9, carbs: 38, fats: 7, servingSize: 6, servingUnit: 'pieces', mealType: mealType),
      'salad bowl': _ParsedFood(name: 'Salad Bowl', calories: 320, protein: 28, carbs: 12, fats: 18, servingSize: 1, servingUnit: 'bowl', mealType: mealType),
      'soup': _ParsedFood(name: 'Soup', calories: 150, protein: 8, carbs: 18, fats: 5, servingSize: 1, servingUnit: 'bowl', mealType: mealType),
      'chicken soup': _ParsedFood(name: 'Chicken Soup', calories: 170, protein: 12, carbs: 15, fats: 7, servingSize: 1, servingUnit: 'bowl', mealType: mealType),
      'shawarma': _ParsedFood(name: 'Shawarma', calories: 500, protein: 30, carbs: 40, fats: 22, servingSize: 1, servingUnit: 'wrap', mealType: mealType),
      'falafel': _ParsedFood(name: 'Falafel', calories: 57, protein: 2.3, carbs: 5.4, fats: 3.4, servingSize: 1, servingUnit: 'piece', mealType: mealType),
      'kebab': _ParsedFood(name: 'Kebab', calories: 550, protein: 35, carbs: 40, fats: 25, servingSize: 1, servingUnit: 'kebab', mealType: mealType),
      // Condiments & Extras
      'honey': _ParsedFood(name: 'Honey', calories: 64, protein: 0.1, carbs: 17, fats: 0, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      'jam': _ParsedFood(name: 'Jam', calories: 56, protein: 0.1, carbs: 14, fats: 0, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      'sugar': _ParsedFood(name: 'Sugar', calories: 49, protein: 0, carbs: 13, fats: 0, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      'ketchup': _ParsedFood(name: 'Ketchup', calories: 20, protein: 0.2, carbs: 5, fats: 0, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
      'mayonnaise': _ParsedFood(name: 'Mayonnaise', calories: 94, protein: 0.1, carbs: 0.1, fats: 10, servingSize: 1, servingUnit: 'tbsp', mealType: mealType),
    };

    // Split compound foods: "eggs and toast", "chicken with rice and broccoli"
    // Tokenize the input to handle "and", "with", "+", ","
    final segments = input
        .replaceAll(RegExp(r'\s+(?:and|with|plus|\+)\s+'), ' , ')
        .split(RegExp(r'\s*[,;]\s*'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final sortedKeys = estimates.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final matched = <String>{};

    // Try matching in each segment first, then fall back to full input
    final searchTexts = segments.length > 1 ? [...segments, input] : [input];

    for (final segment in searchTexts) {
      final seg = segment.trim().toLowerCase();
      for (final key in sortedKeys) {
        if (!seg.contains(key)) continue;
        if (matched.any((m) => m.contains(key) || key.contains(m))) continue;

        double multiplier = 1.0;

        // Try gram-based quantity: "200g chicken", "150 grams of rice"
        final gramMatch = RegExp('(\\d+(?:\\.\\d+)?)\\s*(?:g|grams?|gr)\\s*(?:of\\s+)?$key').firstMatch(seg);
        // Try explicit count: "4 eggs", "2 toast", "3 scoops protein"
        final countMatch = RegExp('(\\d+)\\s+(?:boiled\\s+|fried\\s+|scrambled\\s+|poached\\s+|grilled\\s+|baked\\s+|raw\\s+)?$key').firstMatch(seg);
        // Try "X ml" for liquids
        final mlMatch = RegExp('(\\d+(?:\\.\\d+)?)\\s*(?:ml|liters?|litres?)\\s*(?:of\\s+)?$key').firstMatch(seg);
        // Try "a/an/some" for implied 1 serving
        final impliedMatch = RegExp('(?:a|an|some)\\s+$key').firstMatch(seg);
        // Try "X oz" for ounces
        final ozMatch = RegExp('(\\d+(?:\\.\\d+)?)\\s*(?:oz|ounces?)\\s*(?:of\\s+)?$key').firstMatch(seg);

        if (gramMatch != null) {
          final qty = double.parse(gramMatch.group(1)!);
          final baseSize = estimates[key]!.servingSize;
          multiplier = baseSize > 0 ? qty / (baseSize > 10 ? baseSize : 100) : 1.0;
        } else if (mlMatch != null) {
          final qty = double.parse(mlMatch.group(1)!);
          final baseSize = estimates[key]!.servingSize;
          multiplier = baseSize > 0 ? qty / baseSize : 1.0;
        } else if (ozMatch != null) {
          final qty = double.parse(ozMatch.group(1)!) * 28.35; // oz to g
          final baseSize = estimates[key]!.servingSize;
          multiplier = baseSize > 0 ? qty / (baseSize > 10 ? baseSize : 100) : 1.0;
        } else if (countMatch != null) {
          final qty = double.parse(countMatch.group(1)!);
          // If serving unit is count-based (egg, slice, scoop, etc.) use directly
          final unit = estimates[key]!.servingUnit;
          if (unit.contains('egg') || unit.contains('slice') || unit.contains('scoop') || unit.contains('cup') || unit.contains('bar') || unit.contains('tbsp') || unit.contains('piece') || unit.contains('serving') || unit.contains('banana') || unit.contains('apple') || unit.contains('orange') || unit.contains('date') || unit.contains('cake') || unit.contains('waffle') || unit.contains('pancake') || unit.contains('tortilla') || unit.contains('wrap') || unit.contains('burger') || unit.contains('sandwich') || unit.contains('burrito') || unit.contains('kebab') || unit.contains('shake') || unit.contains('bowl') || unit.contains('bagel') || unit.contains('pizza')) {
            multiplier = qty;
          } else {
            // For gram-based items, small numbers = count, large = grams
            multiplier = qty <= 10 ? qty : qty / estimates[key]!.servingSize;
          }
        } else if (impliedMatch != null) {
          multiplier = 1.0;
        }

        final base = estimates[key]!;
        foods.add(_ParsedFood(name: base.name, calories: base.calories * multiplier, protein: base.protein * multiplier, carbs: base.carbs * multiplier, fats: base.fats * multiplier, servingSize: base.servingSize * multiplier, servingUnit: base.servingUnit, mealType: mealType));
        matched.add(key);
      }
    }
    return foods;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Workout parser
  // ═══════════════════════════════════════════════════════════════════════════

  static List<_ParsedWorkoutDay> _parseWorkoutText(String message) {
    // Normalize: split on newlines, pipes, and semicolons — then rejoin as lines
    final normalizedMessage = message.replaceAll('|', '\n').replaceAll(';', '\n');
    final lines = normalizedMessage.split('\n');
    final days = <_ParsedWorkoutDay>[];
    String? currentDayLabel;
    var currentExercises = <_ParsedExercise>[];
    int defaultSets = 3;
    int defaultReps = 12;
    int parsedDuration = 60;

    final globalSetsMatch = RegExp(r'(\d+)\s*sets?', caseSensitive: false).firstMatch(message);
    if (globalSetsMatch != null) defaultSets = int.parse(globalSetsMatch.group(1)!);
    final globalRepsMatch = RegExp(r'(\d+)[\s\-]*(?:\d+)?\s*reps?', caseSensitive: false).firstMatch(message);
    if (globalRepsMatch != null) defaultReps = int.parse(globalRepsMatch.group(1)!);

    // Extract duration: "60 min", "45 minutes", "1h30", "90min"
    final durationMatch = RegExp(r'(\d+)\s*(?:min(?:utes?)?|mins?)\b', caseSensitive: false).firstMatch(message);
    if (durationMatch != null) parsedDuration = int.parse(durationMatch.group(1)!);
    final durationHourMatch = RegExp(r'(\d+)\s*(?:h(?:ours?)?|hr)\s*(\d+)?', caseSensitive: false).firstMatch(message);
    if (durationHourMatch != null) {
      parsedDuration = int.parse(durationHourMatch.group(1)!) * 60 + (durationHourMatch.group(2) != null ? int.parse(durationHourMatch.group(2)!) : 0);
    }

    // Parse text month dates: "March 12", "Jan 5", "February 20 2026"
    DateTime? parsedDate;
    final monthNames = <String, int>{'jan': 1, 'january': 1, 'feb': 2, 'february': 2, 'mar': 3, 'march': 3, 'apr': 4, 'april': 4, 'may': 5, 'jun': 6, 'june': 6, 'jul': 7, 'july': 7, 'aug': 8, 'august': 8, 'sep': 9, 'september': 9, 'oct': 10, 'october': 10, 'nov': 11, 'november': 11, 'dec': 12, 'december': 12};
    final textDateMatch = RegExp(r'(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(\d{1,2})(?:\s*,?\s*(\d{4}))?', caseSensitive: false).firstMatch(message);
    if (textDateMatch != null) {
      final month = monthNames[textDateMatch.group(1)!.toLowerCase()] ?? 1;
      final day = int.parse(textDateMatch.group(2)!);
      final year = textDateMatch.group(3) != null ? int.parse(textDateMatch.group(3)!) : DateTime.now().year;
      parsedDate = DateTime(year, month, day);
    }

    // Also try "12 March", "5 Jan 2026"
    final textDateMatch2 = RegExp(r'(\d{1,2})\s+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)(?:\s*,?\s*(\d{4}))?', caseSensitive: false).firstMatch(message);
    if (parsedDate == null && textDateMatch2 != null) {
      final day = int.parse(textDateMatch2.group(1)!);
      final month = monthNames[textDateMatch2.group(2)!.toLowerCase()] ?? 1;
      final year = textDateMatch2.group(3) != null ? int.parse(textDateMatch2.group(3)!) : DateTime.now().year;
      parsedDate = DateTime(year, month, day);
    }

    // Handle "today", "yesterday", "last Monday" etc.
    final lowerMsg = message.toLowerCase();
    if (parsedDate == null) {
      if (lowerMsg.contains('today')) parsedDate = DateTime.now();
      else if (lowerMsg.contains('yesterday')) parsedDate = DateTime.now().subtract(const Duration(days: 1));
      else {
        final lastDayMatch = RegExp(r'last\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false).firstMatch(message);
        if (lastDayMatch != null) {
          final dayMap = {'monday': DateTime.monday, 'tuesday': DateTime.tuesday, 'wednesday': DateTime.wednesday, 'thursday': DateTime.thursday, 'friday': DateTime.friday, 'saturday': DateTime.saturday, 'sunday': DateTime.sunday};
          final targetWeekday = dayMap[lastDayMatch.group(1)!.toLowerCase()]!;
          var d = DateTime.now().subtract(const Duration(days: 1));
          while (d.weekday != targetWeekday) { d = d.subtract(const Duration(days: 1)); }
          parsedDate = d;
        }
      }
    }

    // Try "Name: SetsxReps(-MaxReps)xWeight kg" format
    // e.g. "Leg Curl: 3x12-15x45 kg" or "Bench Press: 4x8x100 kg"
    final structuredPattern = RegExp(r'([a-zA-Z][\w\s\-]*?)\s*:\s*(\d+)\s*[x×]\s*(\d+)(?:\s*[\-–]\s*\d+)?\s*[x×]\s*(\d+(?:\.\d+)?)\s*(?:kg|lbs?|lb)', caseSensitive: false);
    for (final m in structuredPattern.allMatches(normalizedMessage)) {
      final name = m.group(1)!.trim();
      if (name.isEmpty || RegExp(r'^\d').hasMatch(name) || _isMetaWord(name)) continue;
      // Skip date/duration fragments
      if (monthNames.containsKey(name.toLowerCase()) || RegExp(r'^\d+\s*min', caseSensitive: false).hasMatch(name)) continue;
      currentExercises.add(_ParsedExercise(name: name, weight: double.parse(m.group(4)!), sets: int.parse(m.group(2)!), reps: int.parse(m.group(3)!)));
    }
    if (currentExercises.isNotEmpty) {
      final label = parsedDate != null ? '${_monthName(parsedDate.month)} ${parsedDate.day} Workout' : 'Workout';
      days.add(_ParsedWorkoutDay(dayLabel: label, exercises: List.from(currentExercises), defaultSets: currentExercises.first.sets ?? defaultSets, defaultReps: currentExercises.first.reps ?? defaultReps));
      if (parsedDate != null) days.last.date = parsedDate;
      days.last.duration = parsedDuration;
      return days;
    }

    // Try "Name: WeightxSetsxReps" or "Name: Weight kg x Sets x Reps" format
    final altStructuredPattern = RegExp(r'([a-zA-Z][\w\s\-]*?)\s*:\s*(\d+(?:\.\d+)?)\s*(?:kg|lbs?|lb)\s*[x×]\s*(\d+)\s*[x×]\s*(\d+)', caseSensitive: false);
    for (final m in altStructuredPattern.allMatches(normalizedMessage)) {
      final name = m.group(1)!.trim();
      if (name.isEmpty || RegExp(r'^\d').hasMatch(name) || _isMetaWord(name)) continue;
      if (monthNames.containsKey(name.toLowerCase())) continue;
      currentExercises.add(_ParsedExercise(name: name, weight: double.parse(m.group(2)!), sets: int.parse(m.group(3)!), reps: int.parse(m.group(4)!)));
    }
    if (currentExercises.isNotEmpty) {
      final label = parsedDate != null ? '${_monthName(parsedDate.month)} ${parsedDate.day} Workout' : 'Workout';
      days.add(_ParsedWorkoutDay(dayLabel: label, exercises: List.from(currentExercises), defaultSets: currentExercises.first.sets ?? defaultSets, defaultReps: currentExercises.first.reps ?? defaultReps));
      if (parsedDate != null) days.last.date = parsedDate;
      days.last.duration = parsedDuration;
      return days;
    }

    // Try "Name - SetsxReps at Weight kg" or "Name, SetsxReps, Weight kg"
    final dashCommaPattern = RegExp(r'([a-zA-Z][\w\s]*?)\s*[\-,]\s*(\d+)\s*[x×]\s*(\d+)(?:\s*[\-–]\s*\d+)?\s*[\-,@]?\s*(?:at\s+)?(\d+(?:\.\d+)?)\s*(?:kg|lbs?|lb)', caseSensitive: false);
    for (final m in dashCommaPattern.allMatches(normalizedMessage)) {
      final name = m.group(1)!.trim();
      if (name.isEmpty || RegExp(r'^\d').hasMatch(name) || _isMetaWord(name)) continue;
      if (monthNames.containsKey(name.toLowerCase())) continue;
      currentExercises.add(_ParsedExercise(name: name, weight: double.parse(m.group(4)!), sets: int.parse(m.group(2)!), reps: int.parse(m.group(3)!)));
    }
    if (currentExercises.isNotEmpty) {
      final label = parsedDate != null ? '${_monthName(parsedDate.month)} ${parsedDate.day} Workout' : 'Workout';
      days.add(_ParsedWorkoutDay(dayLabel: label, exercises: List.from(currentExercises), defaultSets: currentExercises.first.sets ?? defaultSets, defaultReps: currentExercises.first.reps ?? defaultReps));
      if (parsedDate != null) days.last.date = parsedDate;
      days.last.duration = parsedDuration;
      return days;
    }

    // Try "Name SetsxReps WeightKg" (no separator, e.g. "Bench Press 3x10 80kg")
    final noSepPattern = RegExp(r'(\b[a-zA-Z][\w\s]*?)\s+(\d+)\s*[x×]\s*(\d+)(?:\s*[\-–]\s*\d+)?\s+(\d+(?:\.\d+)?)\s*(?:kg|lbs?|lb)', caseSensitive: false);
    for (final m in noSepPattern.allMatches(normalizedMessage)) {
      final name = m.group(1)!.trim();
      if (name.isEmpty || RegExp(r'^\d').hasMatch(name) || _isMetaWord(name)) continue;
      if (monthNames.containsKey(name.toLowerCase())) continue;
      currentExercises.add(_ParsedExercise(name: name, weight: double.parse(m.group(4)!), sets: int.parse(m.group(2)!), reps: int.parse(m.group(3)!)));
    }
    if (currentExercises.isNotEmpty) {
      final label = parsedDate != null ? '${_monthName(parsedDate.month)} ${parsedDate.day} Workout' : 'Workout';
      days.add(_ParsedWorkoutDay(dayLabel: label, exercises: List.from(currentExercises), defaultSets: currentExercises.first.sets ?? defaultSets, defaultReps: currentExercises.first.reps ?? defaultReps));
      if (parsedDate != null) days.last.date = parsedDate;
      days.last.duration = parsedDuration;
      return days;
    }

    // Try natural inline: "bench 80kg 3x10"
    final inlinePattern = RegExp(r'(\b[a-zA-Z][\w\s]*?)\s+(\d+(?:\.\d+)?)\s*(?:kg|lbs?)\s+(\d+)\s*[x×]\s*(\d+)', caseSensitive: false);
    for (final m in inlinePattern.allMatches(normalizedMessage)) {
      final name = m.group(1)!.trim();
      if (name.isEmpty || RegExp(r'^\d').hasMatch(name) || _isMetaWord(name)) continue;
      currentExercises.add(_ParsedExercise(name: name, weight: double.parse(m.group(2)!), sets: int.parse(m.group(3)!), reps: int.parse(m.group(4)!)));
    }
    if (currentExercises.isNotEmpty) {
      final label = parsedDate != null ? '${_monthName(parsedDate.month)} ${parsedDate.day} Workout' : 'Workout';
      days.add(_ParsedWorkoutDay(dayLabel: label, exercises: List.from(currentExercises), defaultSets: currentExercises.first.sets ?? defaultSets, defaultReps: currentExercises.first.reps ?? defaultReps));
      if (parsedDate != null) days.last.date = parsedDate;
      days.last.duration = parsedDuration;
      return days;
    }

    // "5x5 squats at 100kg"
    final setsFirstPattern = RegExp(r'(\d+)\s*[x×]\s*(\d+)\s+([\w\s]+?)\s+(?:at\s+)?(\d+(?:\.\d+)?)\s*(?:kg|lbs?)', caseSensitive: false);
    for (final m in setsFirstPattern.allMatches(normalizedMessage)) {
      final name = m.group(3)!.trim();
      if (name.isEmpty || _isMetaWord(name)) continue;
      currentExercises.add(_ParsedExercise(name: name, weight: double.parse(m.group(4)!), sets: int.parse(m.group(1)!), reps: int.parse(m.group(2)!)));
    }
    if (currentExercises.isNotEmpty) {
      final label = parsedDate != null ? '${_monthName(parsedDate.month)} ${parsedDate.day} Workout' : 'Workout';
      days.add(_ParsedWorkoutDay(dayLabel: label, exercises: List.from(currentExercises), defaultSets: currentExercises.first.sets ?? defaultSets, defaultReps: currentExercises.first.reps ?? defaultReps));
      if (parsedDate != null) days.last.date = parsedDate;
      days.last.duration = parsedDuration;
      return days;
    }

    // "3 sets of curls at 15kg for 12 reps"
    final verbosePattern = RegExp(r'(\d+)\s+sets?\s+(?:of\s+)?([\w\s]+?)\s+(?:at\s+)?(\d+(?:\.\d+)?)\s*(?:kg|lbs?)(?:\s+(?:for\s+)?(\d+)\s+reps?)?', caseSensitive: false);
    for (final m in verbosePattern.allMatches(normalizedMessage)) {
      final name = m.group(2)!.trim();
      if (name.isEmpty || _isMetaWord(name)) continue;
      currentExercises.add(_ParsedExercise(name: name, weight: double.parse(m.group(3)!), sets: int.parse(m.group(1)!), reps: m.group(4) != null ? int.parse(m.group(4)!) : defaultReps));
    }
    if (currentExercises.isNotEmpty) {
      final label = parsedDate != null ? '${_monthName(parsedDate.month)} ${parsedDate.day} Workout' : 'Workout';
      days.add(_ParsedWorkoutDay(dayLabel: label, exercises: List.from(currentExercises), defaultSets: currentExercises.first.sets ?? defaultSets, defaultReps: currentExercises.first.reps ?? defaultReps));
      if (parsedDate != null) days.last.date = parsedDate;
      days.last.duration = parsedDuration;
      return days;
    }

    // Line-by-line parsing
    currentExercises = [];
    DateTime? referenceDate = parsedDate;
    String? referenceDayName;

    final dateMatch = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})').firstMatch(message);
    if (dateMatch != null && referenceDate == null) {
      final p1 = int.parse(dateMatch.group(1)!);
      final p2 = int.parse(dateMatch.group(2)!);
      var p3 = int.parse(dateMatch.group(3)!);
      if (p3 < 100) p3 += 2000;
      if (p1 <= 31 && p2 <= 12) referenceDate = DateTime(p3, p2, p1);
      else if (p2 <= 31 && p1 <= 12) referenceDate = DateTime(p3, p1, p2);
    }

    final refDayMatch = RegExp(r'(?:latest|last|most recent).*?(?:on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false).firstMatch(message.toLowerCase());
    if (refDayMatch != null) { referenceDayName = refDayMatch.group(1); }
    else {
      final onDayMatch = RegExp(r'(?:on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+\d', caseSensitive: false).firstMatch(message.toLowerCase());
      if (onDayMatch != null) referenceDayName = onDayMatch.group(1);
    }

    int dayNameToWeekday(String name) {
      switch (name.toLowerCase().trim().replaceAll(':', '')) {
        case 'monday': return DateTime.monday;
        case 'tuesday': return DateTime.tuesday;
        case 'wednesday': return DateTime.wednesday;
        case 'thursday': return DateTime.thursday;
        case 'friday': return DateTime.friday;
        case 'saturday': return DateTime.saturday;
        case 'sunday': return DateTime.sunday;
        default: return 0;
      }
    }

    final dayHeaderPattern = RegExp(r'^\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday|day\s*\d+)\s*:?\s*$', caseSensitive: false);
    final exercisePattern = RegExp(r'^\s*(.+?)\s*[:\-]\s*(\d+(?:\.\d+)?)\s*(?:kg|lbs?|lb)?\s*$', caseSensitive: false);
    final exercisePatternNoSep = RegExp(r'^\s*([a-zA-Z][\w\s]+?)\s+(\d+(?:\.\d+)?)\s*(?:kg|lbs?|lb)\s*$', caseSensitive: false);
    final weekHeaderPattern = RegExp(r'^\s*week\s*\d+\s*:?\s*$', caseSensitive: false);

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || weekHeaderPattern.hasMatch(trimmed) || _isMetaLine(trimmed)) continue;
      final dayMatch = dayHeaderPattern.firstMatch(trimmed);
      if (dayMatch != null) {
        if (currentDayLabel != null && currentExercises.isNotEmpty) {
          days.add(_ParsedWorkoutDay(dayLabel: currentDayLabel, exercises: List.from(currentExercises), defaultSets: defaultSets, defaultReps: defaultReps));
        }
        currentDayLabel = dayMatch.group(1)!.trim();
        currentExercises = [];
        continue;
      }
      var exMatch = exercisePattern.firstMatch(trimmed);
      exMatch ??= exercisePatternNoSep.firstMatch(trimmed);
      if (exMatch != null) {
        final name = exMatch.group(1)!.trim();
        if (RegExp(r'^\d').hasMatch(name)) continue;
        currentExercises.add(_ParsedExercise(name: name, weight: double.parse(exMatch.group(2)!)));
      }
    }

    if (currentExercises.isNotEmpty) {
      days.add(_ParsedWorkoutDay(dayLabel: currentDayLabel ?? 'Workout', exercises: List.from(currentExercises), defaultSets: defaultSets, defaultReps: defaultReps));
    }

    // Assign dates
    if (referenceDate != null && days.isNotEmpty) {
      int? refIndex;
      if (referenceDayName != null) {
        for (int i = 0; i < days.length; i++) {
          if (days[i].dayLabel.toLowerCase().trim() == referenceDayName.toLowerCase().trim()) { refIndex = i; break; }
        }
      }
      refIndex ??= days.length - 1;
      if (referenceDayName != null) {
        final refWeekday = dayNameToWeekday(referenceDayName);
        if (refWeekday > 0) {
          for (int i = 0; i < days.length; i++) {
            final dayWeekday = dayNameToWeekday(days[i].dayLabel);
            if (dayWeekday > 0) {
              int offset = dayWeekday - refWeekday;
              if (i < refIndex! && offset > 0) offset -= 7;
              if (i > refIndex && offset < 0) offset += 7;
              days[i].date = referenceDate.add(Duration(days: offset));
            } else {
              days[i].date = referenceDate.add(Duration(days: i - refIndex!));
            }
          }
        }
      } else {
        for (int i = days.length - 1; i >= 0; i--) {
          days[i].date = referenceDate.subtract(Duration(days: days.length - 1 - i));
        }
      }
    } else {
      final now = DateTime.now();
      for (int i = days.length - 1; i >= 0; i--) {
        days[i].date = now.subtract(Duration(days: days.length - 1 - i));
      }
    }
    // Apply parsed duration to all days
    for (final day in days) { day.duration = parsedDuration; }
    return days;
  }

  static bool _isMetaLine(String line) => _metaPhrases.any((p) => line.toLowerCase().contains(p));
  static bool _isMetaWord(String word) => const ['i', 'did', 'log', 'my', 'the', 'these', 'at', 'for'].contains(word.toLowerCase().trim());
  static const _metaPhrases = ['log these', 'log my', 'record these', 'record my', 'track my', 'save my', 'i did everything', 'i did all', 'i want u', 'i want you', 'count back', 'latest workout', 'most recent', 'for the exact', 'which is my', 'sets and', 'reps for'];

  static MuscleGroup _guessMuscle(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (_containsAny(lower, ['squat', 'leg press', 'leg extension', 'leg curl', 'lunge', 'bulgarian', 'hack squat', 'calf', 'calves', 'hip thrust'])) {
      if (_containsAny(lower, ['curl', 'hamstring'])) return MuscleGroup.hamstrings;
      if (_containsAny(lower, ['calf', 'calves'])) return MuscleGroup.calves;
      if (_containsAny(lower, ['hip thrust', 'glute'])) return MuscleGroup.glutes;
      return MuscleGroup.quadriceps;
    }
    if (_containsAny(lower, ['pulldown', 'pull-down', 'pull down', 'lat pull', 'row', 'pull up', 'pull-up', 'pullup', 'chin up', 'chin-up', 'deadlift', 'back extension', 't-bar', 'cable row'])) {
      if (_containsAny(lower, ['lat', 'pulldown', 'pull-down', 'pull down'])) return MuscleGroup.lats;
      return MuscleGroup.back;
    }
    if (_containsAny(lower, ['bench', 'chest', 'pec fly', 'pec deck', 'pec machine', 'chest press', 'push up', 'push-up', 'dip', 'incline press', 'decline press', 'isolateral bench'])) return MuscleGroup.chest;
    if (_containsAny(lower, ['shoulder', 'overhead press', 'ohp', 'military press', 'lateral raise', 'front raise', 'rear delt', 'face pull', 'shoulder press', 'arnold'])) return MuscleGroup.shoulders;
    if (_containsAny(lower, ['shrug', 'trap'])) return MuscleGroup.traps;
    if (_containsAny(lower, ['bicep', 'curl', 'hammer'])) return MuscleGroup.biceps;
    if (_containsAny(lower, ['tricep', 'pushdown', 'push down', 'push-down', 'skullcrusher', 'skull crusher', 'overhead extension', 'triceps bar', 'dip'])) return MuscleGroup.triceps;
    if (_containsAny(lower, ['ab', 'crunch', 'plank', 'core', 'sit up'])) return MuscleGroup.core;
    return MuscleGroup.chest;
  }

  static bool _containsAny(String input, List<String> terms) => terms.any((t) => input.contains(t));

  static String _monthName(int month) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month.clamp(1, 12)];

  List<AiAction> _buildWorkoutActions(List<_ParsedWorkoutDay> days) {
    final actions = <AiAction>[];
    for (final day in days) {
      final exercises = <Map<String, dynamic>>[];
      for (final ex in day.exercises) {
        final muscle = _guessMuscle(ex.name);
        final sets = <Map<String, dynamic>>[];
        final numSets = ex.sets ?? day.defaultSets;
        final numReps = ex.reps ?? day.defaultReps;
        for (int i = 0; i < numSets; i++) { sets.add({'weight': ex.weight, 'reps': numReps}); }
        exercises.add({'name': ex.name, 'primary_muscle': muscle.name, 'sets': sets});
      }
      final dateStr = day.date != null ? '${day.date!.year}-${day.date!.month.toString().padLeft(2, '0')}-${day.date!.day.toString().padLeft(2, '0')}' : null;
      final workoutName = day.dayLabel.contains(RegExp(r'(?:mon|tue|wed|thu|fri|sat|sun)', caseSensitive: false)) ? '${day.dayLabel} Workout' : day.dayLabel;
      actions.add(AiAction(type: 'log_workout', label: 'Log $workoutName', data: {'name': workoutName, 'duration_minutes': day.duration, if (dateStr != null) 'date': '${dateStr}T10:00:00', 'exercises': exercises}));
    }
    return actions;
  }

  AiChatResponse _handleWorkoutLogging(String message, _UserContext ctx, {Map<String, dynamic>? context}) {
    final days = _parseWorkoutText(message);
    if (days.isEmpty) {
      final namePrefix = ctx.name != null && ctx.name!.isNotEmpty ? '${ctx.name}, ' : '';
      return AiChatResponse(
        message: '${namePrefix}I can see you want to log workouts, but I couldn\'t parse the exercise data. Try one of these formats:\n\n**Quick format:**\nbench 80kg 3x10\nsquat 100kg 5x5\n\n**Structured format:**\nThursday:\nBench Press: 80 kg\nSquat: 100 kg\n\n**Verbose format:**\n3 sets of curls at 15kg for 12 reps',
        suggestions: ['Show me the format again', 'Log today\'s workout'],
      );
    }
    final actions = _buildWorkoutActions(days);
    final totalExercises = days.fold<int>(0, (sum, d) => sum + d.exercises.length);
    final dayDescriptions = days.map((d) {
      final dateLabel = d.date != null ? ' (${d.date!.day}/${d.date!.month}/${d.date!.year})' : '';
      final exerciseList = d.exercises.map((e) {
        final setsInfo = e.sets != null && e.reps != null ? ' ${e.sets}x${e.reps}' : ' ${d.defaultSets}x${d.defaultReps}';
        return '  • ${e.name}: ${e.weight}kg$setsInfo';
      }).join('\n');
      return '${d.dayLabel}$dateLabel:\n$exerciseList';
    }).join('\n\n');

    return AiChatResponse(
      message: 'Logging ${days.length} workout${days.length > 1 ? 's' : ''} with $totalExercises exercises total:\n\n$dayDescriptions',
      suggestions: ['Show my workout history', 'Recommend a workout split', 'How do I progressively overload?'],
      actions: actions,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Body metric logging
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handleBodyMetricLogging(String message, _UserContext ctx) {
    double? weight;
    double? bodyFat;

    // Extract weight: "I weigh 82 kg", "scale says 80.5", "82kg", "I'm at 75 kg"
    final weightMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?|pounds?|lbs?)\b', caseSensitive: false).firstMatch(message);
    if (weightMatch != null) {
      weight = double.parse(weightMatch.group(1)!);
      // Convert lbs to kg if needed
      if (RegExp(r'(?:pounds?|lbs?)\b', caseSensitive: false).hasMatch(weightMatch.group(0)!)) {
        weight = weight * 0.453592;
      }
    }

    // Extract body fat: "body fat is 15%", "bf 12.5%", "15% body fat"
    final bfMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%', caseSensitive: false).firstMatch(message);
    if (bfMatch != null) bodyFat = double.parse(bfMatch.group(1)!);

    if (weight == null && bodyFat == null) {
      return AiChatResponse(
        message: 'I can log your body metrics! Just tell me your weight or body fat percentage.\n\nExamples:\n- "I weigh 82 kg"\n- "Body fat is 15%"\n- "Scale says 80.5 kg, body fat 14%"',
        suggestions: ['Log my weight', 'Show my progress', 'What should my target weight be?'],
      );
    }

    final actions = <AiAction>[];
    final data = <String, dynamic>{};
    if (weight != null) data['weight'] = weight;
    if (bodyFat != null) data['body_fat_percentage'] = bodyFat;
    data['notes'] = 'Logged via AI Coach';

    actions.add(AiAction(type: 'log_body_metric', label: 'Log body metrics', data: data));

    final parts = <String>[];
    if (weight != null) parts.add('**Weight:** ${weight.toStringAsFixed(1)} kg');
    if (bodyFat != null) parts.add('**Body Fat:** ${bodyFat.toStringAsFixed(1)}%');

    String analysis = '';
    if (weight != null) {
      final diff = weight - ctx.weight;
      if (diff.abs() > 0.3) {
        analysis = diff > 0
            ? '\n\nThat\'s ${diff.toStringAsFixed(1)} kg above your profile weight (${ctx.weight.toStringAsFixed(1)} kg). ${ctx.goal == WorkoutGoal.hypertrophy ? "Could be lean mass gains!" : "Monitor the trend over the next week."}'
            : '\n\nThat\'s ${diff.abs().toStringAsFixed(1)} kg below your profile weight (${ctx.weight.toStringAsFixed(1)} kg). ${ctx.goal == WorkoutGoal.fatLoss ? "Great progress on your cut!" : "Make sure you\'re eating enough."}';
      }
    }

    return AiChatResponse(
      message: 'Logging your body metrics:\n\n${parts.join('\n')}$analysis',
      suggestions: ['Show my progress', 'How\'s my weight trending?', 'What should my macros be?'],
      actions: actions,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // View progress
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handleViewProgress(_UserContext ctx, Map<String, dynamic>? context) {
    final todayCal = (context?['todayCalories'] as num?)?.toDouble() ?? 0;
    final todayPro = (context?['todayProtein'] as num?)?.toDouble() ?? 0;
    final todayCarbs = (context?['todayCarbs'] as num?)?.toDouble() ?? 0;
    final todayFats = (context?['todayFats'] as num?)?.toDouble() ?? 0;
    final mealsToday = (context?['todayMealsCount'] as int?) ?? 0;
    final workoutsWeek = (context?['workoutsThisWeek'] as int?) ?? 0;
    final namePrefix = ctx.name != null && ctx.name!.isNotEmpty ? '${ctx.name}, h' : 'H';

    final calProgress = ctx.calorieTarget > 0 ? (todayCal / ctx.calorieTarget * 100).round() : 0;
    final proProgress = ctx.proteinTarget > 0 ? (todayPro / ctx.proteinTarget * 100).round() : 0;

    final buffer = StringBuffer();
    buffer.writeln('${namePrefix}ere\'s your overview:\n');
    buffer.writeln('📊 **Today\'s Nutrition**');
    buffer.writeln('• Calories: ${todayCal.round()} / ${ctx.calorieTarget.round()} kcal ($calProgress%)');
    buffer.writeln('• Protein: ${todayPro.round()} / ${ctx.proteinTarget.round()}g ($proProgress%)');
    buffer.writeln('• Carbs: ${todayCarbs.round()} / ${ctx.carbsTarget.round()}g');
    buffer.writeln('• Fats: ${todayFats.round()} / ${ctx.fatsTarget.round()}g');
    buffer.writeln('• Meals logged: $mealsToday');
    buffer.writeln();
    buffer.writeln('💪 **This Week**');
    buffer.writeln('• Workouts: $workoutsWeek / ${ctx.workoutDays}');

    final remaining = ctx.calorieTarget - todayCal;
    if (remaining > 0) {
      buffer.writeln('\n📌 You still have ${remaining.round()} kcal and ${(ctx.proteinTarget - todayPro).round()}g protein to hit your targets.');
    } else if (remaining < -100) {
      buffer.writeln('\n⚠️ You\'re ${remaining.abs().round()} kcal over your target. Consider lighter options for the rest of the day.');
    } else {
      buffer.writeln('\n✅ You\'re right on target! Keep it up.');
    }

    return AiChatResponse(
      message: buffer.toString(),
      suggestions: ['Log a meal', 'Log a workout', 'What should I eat next?', 'Show workout calendar'],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Plan workout
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handlePlanWorkout(_UserContext ctx, Map<String, dynamic>? context) {
    final workoutsWeek = (context?['workoutsThisWeek'] as int?) ?? 0;
    final dayOfWeek = DateTime.now().weekday;
    final dayName = _dayName(dayOfWeek);
    final namePrefix = ctx.name != null && ctx.name!.isNotEmpty ? '${ctx.name}, ' : '';

    // Determine what to train based on split and what's been done this week
    String focus;
    List<String> exercises;
    String splitRec;

    if (ctx.workoutDays <= 3) {
      // Full body
      focus = 'Full Body';
      exercises = ['Squat: 4×6-8', 'Bench Press: 3×8-10', 'Barbell Row: 3×8-10', 'Overhead Press: 3×8-10', 'Romanian Deadlift: 3×10-12'];
      splitRec = 'Since you train ${ctx.workoutDays}×/week, a full body session works best.';
    } else if (ctx.workoutDays <= 4) {
      // Upper/Lower
      final isUpper = workoutsWeek % 2 == 0;
      focus = isUpper ? 'Upper Body' : 'Lower Body';
      exercises = isUpper
          ? ['Bench Press: 4×6-8', 'Barbell Row: 4×8-10', 'Overhead Press: 3×8-10', 'Pull-ups: 3×max', 'Lateral Raises: 3×12-15']
          : ['Squat: 4×6-8', 'Romanian Deadlift: 3×8-10', 'Leg Press: 3×10-12', 'Leg Curl: 3×10-12', 'Calf Raises: 4×12-15'];
      splitRec = 'Following an Upper/Lower split for ${ctx.workoutDays}×/week.';
    } else {
      // PPL
      final pplIndex = workoutsWeek % 3;
      focus = ['Push (Chest/Shoulders/Triceps)', 'Pull (Back/Biceps)', 'Legs'][pplIndex];
      exercises = [
        if (pplIndex == 0) ...['Bench Press: 4×6-8', 'Incline DB Press: 3×8-10', 'Overhead Press: 3×8-10', 'Lateral Raises: 3×12-15', 'Tricep Pushdowns: 3×10-12'],
        if (pplIndex == 1) ...['Pull-ups: 4×6-10', 'Barbell Row: 4×8-10', 'Cable Row: 3×10-12', 'Face Pulls: 3×15-20', 'Barbell Curls: 3×10-12'],
        if (pplIndex == 2) ...['Squat: 4×6-8', 'Romanian Deadlift: 3×8-10', 'Leg Press: 3×10-12', 'Leg Curl: 3×10-12', 'Calf Raises: 4×12-15'],
      ];
      splitRec = 'Following a Push/Pull/Legs split for ${ctx.workoutDays}×/week.';
    }

    return AiChatResponse(
      message: '$namePrefix$dayName workout suggestion — **$focus**:\n\n$splitRec\n\n${exercises.map((e) => '• $e').join('\n')}\n\nYou\'ve completed $workoutsWeek / ${ctx.workoutDays} workouts this week. ${workoutsWeek < ctx.workoutDays ? "Let\'s get this one in!" : "You\'ve already hit your target — this is bonus work!"}',
      suggestions: ['Log this workout', 'Show different exercises', 'How do I progressively overload?'],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Greeting handler
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handleGreeting(_UserContext ctx, Map<String, dynamic>? context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final nameStr = ctx.name != null && ctx.name!.isNotEmpty ? ', ${ctx.name}' : '';

    final todayCal = (context?['todayCalories'] as num?)?.toDouble() ?? 0;
    final mealsToday = (context?['todayMealsCount'] as int?) ?? 0;
    final workoutsWeek = (context?['workoutsThisWeek'] as int?) ?? 0;

    String quickStatus = '';
    if (mealsToday > 0 || workoutsWeek > 0) {
      final parts = <String>[];
      if (mealsToday > 0) parts.add('${todayCal.round()} kcal logged today');
      if (workoutsWeek > 0) parts.add('$workoutsWeek workout${workoutsWeek > 1 ? 's' : ''} this week');
      quickStatus = '\n\n📊 Quick status: ${parts.join(', ')}.';
    }

    String timeTip = '';
    if (hour >= 5 && hour < 10 && mealsToday == 0) {
      timeTip = '\n\n💡 Don\'t forget to fuel your morning! Want to log breakfast?';
    } else if (hour >= 12 && hour < 14 && mealsToday <= 1) {
      timeTip = '\n\n💡 Lunchtime! Have you eaten yet?';
    } else if (hour >= 17 && hour < 20) {
      timeTip = '\n\n💡 Evening! ${workoutsWeek < ctx.workoutDays ? "There\'s still time for a workout today." : "Great job hitting your workout target this week!"}';
    }

    return AiChatResponse(
      message: '$greeting$nameStr! 👋 How can I help you today?$quickStatus$timeTip',
      suggestions: ['Log a meal', 'Log a workout', 'What should I eat?', 'How am I doing today?'],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Nutritionist agent
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handleNutrition(_QueryIntent intent, String input, _UserContext ctx, {String? originalMessage, Map<String, dynamic>? context}) {
    switch (intent) {
      case _QueryIntent.logMeal: return _handleMealLogging(originalMessage ?? input, ctx, context: context);
      case _QueryIntent.logBodyMetric: return _handleBodyMetricLogging(originalMessage ?? input, ctx);
      case _QueryIntent.viewProgress: return _handleViewProgress(ctx, context);
      case _QueryIntent.planWorkout: return _handlePlanWorkout(ctx, context);
      case _QueryIntent.greeting: return _handleGreeting(ctx, context);
      case _QueryIntent.calories: return _calorieResponse(ctx);
      case _QueryIntent.protein: return _proteinResponse(ctx);
      case _QueryIntent.macros: return _macroResponse(ctx);
      case _QueryIntent.mealTiming: return _mealTimingResponse(ctx);
      case _QueryIntent.fatLoss: return _fatLossNutritionResponse(ctx);
      case _QueryIntent.muscleGain: return _muscleGainNutritionResponse(ctx);
      case _QueryIntent.hydration: return _hydrationResponse(ctx);
      case _QueryIntent.supplements: return _supplementResponse(ctx);
      default:
        if (_containsPhrase(input, ['protein'])) return _proteinResponse(ctx);
        if (_containsPhrase(input, ['calorie', 'calories'])) return _calorieResponse(ctx);
        return _defaultNutritionResponse(ctx);
    }
  }

  AiChatResponse _calorieResponse(_UserContext ctx) {
    final deficitCal = (ctx.tdee - 500).round();
    final surplusCal = (ctx.tdee + 300).round();
    String goalRec;
    switch (ctx.goal) {
      case WorkoutGoal.fatLoss: goalRec = 'For fat loss, aim for $deficitCal kcal/day (a ~500 kcal deficit). This should produce roughly 0.5 kg of fat loss per week while preserving muscle, provided you keep protein high.';
      case WorkoutGoal.hypertrophy: goalRec = 'For muscle gain, aim for $surplusCal kcal/day (a ~300 kcal surplus). This fuels growth while limiting excess fat gain. Adjust up if the scale does not move after 2 weeks.';
      case WorkoutGoal.strength: goalRec = 'For strength goals, eat at or slightly above maintenance (${ctx.tdee.round()}--$surplusCal kcal/day). Extra fuel helps recovery from heavy sessions without unnecessary fat gain.';
      case WorkoutGoal.generalFitness: goalRec = 'For general fitness, eating near maintenance (${ctx.tdee.round()} kcal/day) keeps you fueled for training without gaining or losing. Adjust based on how your clothes fit and energy levels.';
      case WorkoutGoal.endurance: goalRec = 'For endurance, you need adequate carbs to fuel sessions. Aim for ${ctx.tdee.round()}--$surplusCal kcal/day on training days, and closer to ${ctx.tdee.round()} kcal on rest days.';
    }
    final namePrefix = ctx.name != null && ctx.name!.isNotEmpty ? '${ctx.name}, b' : 'B';
    return AiChatResponse(
      message: '${namePrefix}ased on your profile (${ctx.weight.round()} kg, ${ctx.height.round()} cm, age ${ctx.age}, training ${ctx.workoutDays}x/week), your estimated TDEE is ~${ctx.tdee.round()} kcal/day.\n\n$goalRec\n\nYour current calorie target is set to ${ctx.calorieTarget.round()} kcal. ${_calorieTargetCheck(ctx)}',
      suggestions: ['What should my macros be?', 'How much protein do I need?', 'Should I eat differently on rest days?'],
    );
  }

  String _calorieTargetCheck(_UserContext ctx) {
    final diff = ctx.calorieTarget - ctx.tdee;
    if (ctx.goal == WorkoutGoal.fatLoss && diff > -200) return 'That looks a bit high for fat loss. Consider lowering to ${(ctx.tdee - 500).round()} kcal.';
    if (ctx.goal == WorkoutGoal.hypertrophy && diff < 100) return 'That might be too low for muscle gain. Consider raising to ${(ctx.tdee + 300).round()} kcal.';
    return 'That looks reasonable for your ${ctx.goal.displayName.toLowerCase()} goal.';
  }

  AiChatResponse _proteinResponse(_UserContext ctx) {
    final target = (ctx.weight * ctx.proteinPerKg).round();
    return AiChatResponse(
      message: 'At ${ctx.weight.round()} kg with a ${ctx.goal.displayName.toLowerCase()} goal, your protein target is ${ctx.proteinPerKg} g/kg, which is ~$target g/day.\n\nYour current target is set to ${ctx.proteinTarget.round()} g. ${_proteinCheck(ctx, target)}\n\nSpread intake across ${ctx.workoutDays >= 4 ? "4-5" : "3-4"} meals with 25-40 g per sitting to maximize muscle protein synthesis.',
      suggestions: ['What should my macros be?', 'Best high-protein foods?', 'How many calories do I need?'],
      actions: [const AiAction(type: 'log_meal', label: 'Log Chicken Breast (100g)', data: {'name': 'Chicken Breast', 'calories': 165, 'protein': 31, 'carbs': 0, 'fats': 3.6, 'fiber': 0, 'meal_type': 'lunch', 'serving_size': 100, 'serving_unit': 'g'})],
    );
  }

  String _proteinCheck(_UserContext ctx, int calculated) {
    final diff = ctx.proteinTarget - calculated;
    if (diff < -15) return 'That is about ${diff.abs().round()} g below the recommended target. Consider increasing it.';
    if (diff > 15) return 'That is ${diff.round()} g above the minimum, which is fine if you prefer higher protein.';
    return 'That is right in the recommended range.';
  }

  AiChatResponse _macroResponse(_UserContext ctx) {
    final proteinG = (ctx.weight * ctx.proteinPerKg).round();
    final fatG = (ctx.weight * 0.9).round();
    final proteinCal = proteinG * 4;
    final fatCal = fatG * 9;
    final carbCal = ctx.calorieTarget - proteinCal - fatCal;
    final carbG = (carbCal / 4).round();
    return AiChatResponse(
      message: 'Based on ${ctx.calorieTarget.round()} kcal/day and your ${ctx.goal.displayName.toLowerCase()} goal, here is a recommended macro split:\n\nProtein: $proteinG g (${(proteinCal / ctx.calorieTarget * 100).round()}%)\nFats: $fatG g (${(fatCal / ctx.calorieTarget * 100).round()}%)\nCarbs: ${carbG > 0 ? carbG : 100} g (remaining calories)\n\nYour current targets: ${ctx.proteinTarget.round()} g P / ${ctx.carbsTarget.round()} g C / ${ctx.fatsTarget.round()} g F.\n\nProtein is set based on ${ctx.proteinPerKg} g/kg for ${ctx.goal.displayName.toLowerCase()}. Fats are set at 0.9 g/kg for hormonal health. Carbs fill the rest and fuel training.',
      suggestions: ['How much protein do I need?', 'Should I carb cycle?', 'What are good fat sources?'],
    );
  }

  AiChatResponse _mealTimingResponse(_UserContext ctx) {
    final mealsPerDay = ctx.workoutDays >= 4 ? '4-5' : '3-4';
    final calPerMeal = (ctx.calorieTarget / (ctx.workoutDays >= 4 ? 4.5 : 3.5)).round();
    return AiChatResponse(
      message: 'At ${ctx.calorieTarget.round()} kcal/day, spread across $mealsPerDay meals, that is roughly $calPerMeal kcal per meal.\n\nPre-workout (1-2 hrs before): carbs + moderate protein (e.g., oats with whey, ~400 kcal).\nPost-workout (within 2 hrs): protein + carbs to replenish glycogen (e.g., chicken and rice, ~500 kcal).\n\nTotal daily intake matters most. Meal timing gives a small extra edge but will not make or break your results.',
      suggestions: ['What should my macros be?', 'Best pre-workout foods?', 'Should I eat before bed?'],
    );
  }

  AiChatResponse _fatLossNutritionResponse(_UserContext ctx) {
    final deficitCal = (ctx.tdee - 500).round();
    final proteinG = (ctx.weight * 2.2).round();
    return AiChatResponse(
      message: 'For fat loss at ${ctx.weight.round()} kg, aim for ~$deficitCal kcal/day (500 below your TDEE of ${ctx.tdee.round()}).\n\nSet protein to $proteinG g/day (2.2 g/kg) to preserve muscle during the deficit. Keep fats at ${(ctx.weight * 0.8).round()} g minimum for hormonal health.\n\nRate of loss: 0.5-1% of bodyweight per week. Faster than that risks muscle loss. Track weekly averages, not daily fluctuations.',
      suggestions: ['How long should I cut for?', 'Can I build muscle in a deficit?', 'High-protein low-calorie foods?'],
    );
  }

  AiChatResponse _muscleGainNutritionResponse(_UserContext ctx) {
    final surplusCal = (ctx.tdee + 300).round();
    final proteinG = (ctx.weight * 2.0).round();
    return AiChatResponse(
      message: 'For muscle gain at ${ctx.weight.round()} kg, aim for ~$surplusCal kcal/day (300 above your TDEE of ${ctx.tdee.round()}).\n\nProtein: $proteinG g/day (2.0 g/kg). Carbs should be high to fuel training — they are your best friend in a gaining phase. Fats at ${(ctx.weight * 1.0).round()} g/day.\n\nExpect to gain 0.25-0.5 kg/week. If gaining faster, you are likely adding unnecessary fat. If not gaining, add 100-200 kcal.',
      suggestions: ['What should my macros be?', 'Best foods for gaining?', 'How to minimize fat gain while bulking?'],
    );
  }

  AiChatResponse _hydrationResponse(_UserContext ctx) {
    return AiChatResponse(
      message: 'At ${ctx.weight.round()} kg, aim for ~${(ctx.weight * 0.035).toStringAsFixed(1)} L/day as a baseline. On training days, increase to ~${(ctx.weight * 0.04 + 0.5).toStringAsFixed(1)} L to account for sweat loss.\n\nCheck your urine color — pale yellow means you are hydrated. Dark yellow means drink more. If you sweat heavily, add a pinch of salt or an electrolyte tab to your water.',
      suggestions: ['How many calories do I need?', 'Best electrolyte sources?', 'Does coffee count as hydration?'],
    );
  }

  AiChatResponse _supplementResponse(_UserContext ctx) {
    return AiChatResponse(
      message: 'Worth taking: creatine monohydrate (5 g/day, the most researched supplement), whey protein if you struggle to hit ${ctx.proteinTarget.round()} g from food, and vitamin D if you do not get regular sun.\n\nSituational: caffeine (3-6 mg/kg pre-workout for performance), fish oil if you do not eat fatty fish twice a week.\n\nSkip: BCAAs (redundant if protein is adequate), fat burners (negligible effect), testosterone boosters (do not work).',
      suggestions: ['How should I take creatine?', 'How much protein do I need?', 'Best pre-workout nutrition?'],
    );
  }

  AiChatResponse _defaultNutritionResponse(_UserContext ctx) {
    return AiChatResponse(
      message: 'Your current nutrition targets: ${ctx.calorieTarget.round()} kcal, ${ctx.proteinTarget.round()} g protein, ${ctx.carbsTarget.round()} g carbs, ${ctx.fatsTarget.round()} g fats.\n\nI can help with calories, macros, meal timing, supplements, or specific diet questions. What would you like to know?',
      suggestions: ['How many calories do I need?', 'What should my macros be?', 'How much protein do I need?'],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Trainer agent
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handleTraining(_QueryIntent intent, String input, _UserContext ctx, {String? originalMessage, Map<String, dynamic>? context}) {
    switch (intent) {
      case _QueryIntent.logMeal: return _handleMealLogging(originalMessage ?? input, ctx, context: context);
      case _QueryIntent.logWorkout: return _handleWorkoutLogging(originalMessage ?? input, ctx, context: context);
      case _QueryIntent.logBodyMetric: return _handleBodyMetricLogging(originalMessage ?? input, ctx);
      case _QueryIntent.viewProgress: return _handleViewProgress(ctx, context);
      case _QueryIntent.planWorkout: return _handlePlanWorkout(ctx, context);
      case _QueryIntent.greeting: return _handleGreeting(ctx, context);
      case _QueryIntent.workoutSplit: return _splitResponse(ctx);
      case _QueryIntent.progressiveOverload: return _overloadResponse(ctx);
      case _QueryIntent.recovery: return _recoveryResponse(ctx);
      case _QueryIntent.volume: return _volumeResponse(ctx);
      case _QueryIntent.exerciseSpecific: return _exerciseResponse(input, ctx);
      default:
        if (_containsPhrase(input, ['split', 'program', 'routine'])) return _splitResponse(ctx);
        if (_containsPhrase(input, ['rest', 'recovery', 'deload'])) return _recoveryResponse(ctx);
        if (_containsPhrase(input, ['chest', 'back', 'legs', 'shoulder', 'arm', 'bicep', 'tricep'])) return _exerciseResponse(input, ctx);
        return _defaultTrainerResponse(ctx);
    }
  }

  AiChatResponse _splitResponse(_UserContext ctx) {
    String recommendation; String rationale;
    switch (ctx.level) {
      case ExperienceLevel.beginner: recommendation = 'Full Body, 3 days/week'; rationale = 'As a beginner, you build strength fastest by hitting each muscle 3x/week with compound movements. Full body lets you practice squat, bench, row, and deadlift patterns frequently. Run this for 3-6 months before switching.';
      case ExperienceLevel.intermediate:
        if (ctx.workoutDays <= 4) { recommendation = 'Upper/Lower, 4 days/week'; rationale = 'At ${ctx.workoutDays} days/week, Upper/Lower gives you 2x frequency per muscle with enough recovery. Day 1: Upper, Day 2: Lower, Day 3: rest, Day 4: Upper, Day 5: Lower, then weekend off.'; }
        else { recommendation = 'Push/Pull/Legs, ${ctx.workoutDays} days/week'; rationale = 'With ${ctx.workoutDays} training days, PPL lets you hit each muscle group twice. Push (chest/shoulders/triceps), Pull (back/biceps), Legs (quads/hamstrings/glutes), then repeat.'; }
      case ExperienceLevel.advanced: recommendation = 'Push/Pull/Legs, ${ctx.workoutDays} days/week'; rationale = 'At your level, PPL with higher volume per session gives you the frequency and volume needed for continued gains. Consider periodizing intensity — alternate heavy (4-6 rep) and moderate (8-12 rep) sessions.';
    }
    return AiChatResponse(message: 'For your experience level (${ctx.level.displayName.toLowerCase()}) training ${ctx.workoutDays}x/week with a ${ctx.goal.displayName.toLowerCase()} goal, I recommend: $recommendation.\n\n$rationale', suggestions: ['How many sets per muscle group?', 'How do I progressively overload?', 'When should I deload?'], actions: const []);
  }

  AiChatResponse _overloadResponse(_UserContext ctx) {
    String levelAdvice;
    switch (ctx.level) {
      case ExperienceLevel.beginner: levelAdvice = 'At your stage, you should be able to add 2.5 kg to upper body lifts and 5 kg to lower body lifts every 1-2 weeks. If a weight feels manageable for all prescribed reps, increase it next session.';
      case ExperienceLevel.intermediate: levelAdvice = 'Progress will be slower now — aim to add weight every 1-2 weeks, or add reps within your target range before increasing weight. Double progression works well: once you hit the top of your rep range for all sets, add 2.5 kg and drop back to the bottom.';
      case ExperienceLevel.advanced: levelAdvice = 'At your level, focus on weekly or monthly progression. Use periodization: spend 3-4 weeks building volume, then test strength. Small rep PRs count. Also consider varying exercise selection every 4-8 weeks to drive new adaptations.';
    }
    return AiChatResponse(message: '$levelAdvice\n\nIf you have truly stalled: check sleep (7-9 hours?), nutrition (eating enough?), and accumulated fatigue (need a deload?). These three fix most plateaus.', suggestions: ['When should I deload?', 'Recommend a workout split', 'How many sets per muscle group?']);
  }

  AiChatResponse _recoveryResponse(_UserContext ctx) {
    final restDays = 7 - ctx.workoutDays;
    return AiChatResponse(
      message: 'Training ${ctx.workoutDays}x/week means $restDays rest days. ${restDays < 2 ? "That is low — make sure at least 1 day is fully off." : "That is a good balance."}\n\nDeload every 4-6 weeks: cut volume by 40-50% for one week. ${ctx.level == ExperienceLevel.beginner ? "As a beginner, you may not need deloads for the first 8-12 weeks." : "At your level, regular deloads prevent overtraining and often lead to PRs the following week."}\n\nSleep 7-9 hours. This is where muscle repair and growth hormone release happen. Poor sleep directly impairs recovery and strength.',
      suggestions: ['Recommend a workout split', 'How do I know if I need a deload?', 'How much protein do I need?'],
    );
  }

  AiChatResponse _volumeResponse(_UserContext ctx) {
    String volumeRec;
    switch (ctx.level) {
      case ExperienceLevel.beginner: volumeRec = '10-12 sets per muscle group per week. Focus on compound movements with 3 sets each. More volume is not better at this stage — learning the movements and recovering properly is the priority.';
      case ExperienceLevel.intermediate: volumeRec = '12-16 sets per muscle group per week. Split across 2 sessions for each muscle. Most sets should be taken within 1-3 reps of failure (RPE 7-9).';
      case ExperienceLevel.advanced: volumeRec = '16-20+ sets per muscle group per week, depending on the muscle. Back and quads can handle more; biceps and triceps need less direct work (they get hit by compounds). Periodize volume across mesocycles.';
    }
    return AiChatResponse(message: 'For ${ctx.level.displayName.toLowerCase()} lifters: $volumeRec\n\nRep ranges: 6-8 for strength, 8-12 for hypertrophy, 12-20 for endurance and isolation work. Mix ranges for best results.', suggestions: ['Recommend a workout split', 'How do I progressively overload?', 'When should I deload?']);
  }

  AiChatResponse _exerciseResponse(String input, _UserContext ctx) {
    if (_containsPhrase(input, ['chest', 'bench', 'pec', 'push'])) return _bodyPartResponse('Chest', ctx, ['Barbell Bench Press: 4x6-8 (primary mass builder)', 'Incline Dumbbell Press: 3x8-10 (upper chest)', 'Cable Flyes: 3x12-15 (stretch/squeeze)'], ['Retract scapulae before pressing', 'Control the lowering for 2-3 seconds']);
    if (_containsPhrase(input, ['back', 'lat', 'row', 'pull'])) return _bodyPartResponse('Back', ctx, ['Pull-Ups or Lat Pulldown: 4x6-10 (width)', 'Barbell Row: 4x8-10 (thickness)', 'Face Pulls: 3x15-20 (rear delts, posture)'], ['Initiate pulls by squeezing shoulder blades', 'Drive elbows back, do not just pull with hands']);
    if (_containsPhrase(input, ['leg', 'squat', 'quad', 'hamstring', 'glute'])) return _bodyPartResponse('Legs', ctx, ['Barbell Squat: 4x6-8 (foundation movement)', 'Romanian Deadlift: 3x8-10 (hamstrings/glutes)', 'Leg Press: 3x10-12 (quad volume)', 'Hip Thrust: 3x10-12 (glute isolation)'], ['Brace core hard before each squat rep', 'Hit at least parallel depth for full quad development']);
    if (_containsPhrase(input, ['shoulder', 'delt', 'overhead'])) return _bodyPartResponse('Shoulders', ctx, ['Overhead Press: 3x6-8 (strength)', 'Lateral Raises: 4x12-15 (width)', 'Face Pulls: 3x15-20 (rear delts)'], ['On lateral raises, lead with elbows not hands', 'Keep overhead presses strict for shoulder safety']);
    if (_containsPhrase(input, ['bicep', 'curl', 'arm'])) return _bodyPartResponse('Arms', ctx, ['Barbell Curl: 3x8-10 (biceps mass)', 'Incline Dumbbell Curl: 3x10-12 (stretch position)', 'Tricep Dips or Pushdowns: 3x10-12 (triceps)', 'Overhead Tricep Extension: 3x10-12 (long head)'], ['Full range of motion beats heavy cheated reps', 'Biceps grow from being stretched under load']);
    return _defaultTrainerResponse(ctx);
  }

  AiChatResponse _bodyPartResponse(String bodyPart, _UserContext ctx, List<String> exercises, List<String> tips) {
    final setsRec = ctx.level == ExperienceLevel.beginner ? '10-12' : ctx.level == ExperienceLevel.intermediate ? '12-16' : '16-20';
    return AiChatResponse(
      message: '$bodyPart routine for ${ctx.level.displayName.toLowerCase()} level, $setsRec sets/week:\n\n${exercises.map((e) => '- $e').join('\n')}\n\nForm cues:\n${tips.map((t) => '- $t').join('\n')}\n\nTrain $bodyPart ${ctx.level == ExperienceLevel.beginner ? "3x/week as part of full body" : "2x/week"} with at least 48 hours between sessions.',
      suggestions: ['Recommend a workout split', 'How do I progressively overload?', 'How many sets per muscle group?'],
      actions: const [],
    );
  }

  AiChatResponse _defaultTrainerResponse(_UserContext ctx) {
    return AiChatResponse(
      message: 'You are training ${ctx.workoutDays}x/week at ${ctx.level.displayName.toLowerCase()} level with a ${ctx.goal.displayName.toLowerCase()} goal.\n\nI can help with workout splits, exercise selection, progressive overload strategy, recovery timing, or form advice. What would you like to focus on?',
      suggestions: ['Recommend a workout split', 'How do I progressively overload?', 'When should I deload?', 'How many sets per muscle group?'],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // General agent
  // ═══════════════════════════════════════════════════════════════════════════

  AiChatResponse _handleGeneral(_QueryIntent intent, String input, _UserContext ctx, {String? originalMessage, Map<String, dynamic>? context}) {
    // Universal handlers
    if (intent == _QueryIntent.greeting) return _handleGreeting(ctx, context);
    if (intent == _QueryIntent.viewProgress) return _handleViewProgress(ctx, context);
    if (intent == _QueryIntent.planWorkout) return _handlePlanWorkout(ctx, context);
    if (intent == _QueryIntent.logBodyMetric) return _handleBodyMetricLogging(originalMessage ?? input, ctx);

    if (const [_QueryIntent.calories, _QueryIntent.protein, _QueryIntent.macros, _QueryIntent.mealTiming, _QueryIntent.fatLoss, _QueryIntent.muscleGain, _QueryIntent.hydration, _QueryIntent.supplements, _QueryIntent.logMeal].contains(intent)) {
      return _handleNutrition(intent, input, ctx, originalMessage: originalMessage, context: context);
    }
    if (const [_QueryIntent.workoutSplit, _QueryIntent.progressiveOverload, _QueryIntent.recovery, _QueryIntent.volume, _QueryIntent.exerciseSpecific, _QueryIntent.logWorkout].contains(intent)) {
      return _handleTraining(intent, input, ctx, originalMessage: originalMessage, context: context);
    }
    return _defaultGeneralResponse(ctx);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Food image analysis, suggestions, advice (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<FoodAnalysisResult> analyzeFoodImage(String imagePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return FoodAnalysisResult(foodName: 'Unknown Food', calories: 0, protein: 0, carbs: 0, fats: 0, confidence: 0.0, servingSize: 'N/A', imageUrl: imagePath);
  }

  @override
  Future<List<FoodSuggestion>> suggestFoods(String query, {Map<String, dynamic>? userContext}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final results = _foodDb.searchFoods(query);
    final goal = userContext?['goal'] as String?;
    List<FoodSuggestion> suggestions = results.map((food) => FoodSuggestion(name: food.name, calories: food.calories, protein: food.protein, carbs: food.carbs, fats: food.fats, category: food.category.displayName, servingSize: '${food.servingSize.toInt()} ${food.servingUnit}')).toList();
    if (goal != null) {
      if (goal.contains('fat') || goal.contains('loss')) { suggestions.sort((a, b) { final aS = a.calories > 0 ? a.protein / a.calories : 0; final bS = b.calories > 0 ? b.protein / b.calories : 0; return bS.compareTo(aS); }); }
      else if (goal.contains('muscle') || goal.contains('gain')) { suggestions.sort((a, b) => b.protein.compareTo(a.protein)); }
    }
    return suggestions.take(15).toList();
  }

  @override
  Future<NutritionAdvice> getNutritionAdvice(String question, {Map<String, dynamic>? userProfile}) async {
    await Future<void>.delayed(Duration(milliseconds: 300 + _random.nextInt(300)));
    final weight = (userProfile?['weight'] as num?)?.toDouble() ?? 75.0;
    final calorieTarget = (userProfile?['dailyCalorieTarget'] as num?)?.toDouble() ?? 2200.0;
    final goalStr = userProfile?['goal'] as String? ?? 'generalFitness';
    WorkoutGoal goal; try { goal = WorkoutGoal.values.byName(goalStr); } catch (_) { goal = WorkoutGoal.generalFitness; }
    double proteinPerKg;
    switch (goal) { case WorkoutGoal.fatLoss: proteinPerKg = 2.2; case WorkoutGoal.hypertrophy: case WorkoutGoal.strength: proteinPerKg = 2.0; case WorkoutGoal.generalFitness: proteinPerKg = 1.8; case WorkoutGoal.endurance: proteinPerKg = 1.6; }
    final proteinG = (weight * proteinPerKg).round(); final fatG = (weight * 0.9).round();
    final carbCal = calorieTarget - (proteinG * 4) - (fatG * 9); final carbG = (carbCal / 4).round().clamp(50, 600);
    return NutritionAdvice(
      advice: 'At ${weight.round()} kg with a ${goal.displayName.toLowerCase()} goal, your recommended targets are:\n\nCalories: ${calorieTarget.round()} kcal/day\nProtein: $proteinG g ($proteinPerKg g/kg)\nFats: $fatG g (0.9 g/kg)\nCarbs: $carbG g (remaining calories)\n\nPrioritize whole foods, hit your protein target daily, and stay consistent with tracking.',
      macroSuggestions: {'protein': '${proteinG}g', 'carbs': '${carbG}g', 'fats': '${fatG}g'},
      mealPlan: [
        MealPlanEntry(mealType: 'breakfast', description: 'Greek yogurt (200g) with oats (40g) and berries', estimatedCalories: (calorieTarget * 0.2).round().toDouble(), estimatedProtein: (proteinG * 0.2).round().toDouble()),
        MealPlanEntry(mealType: 'lunch', description: 'Chicken breast (150g) with rice and vegetables', estimatedCalories: (calorieTarget * 0.3).round().toDouble(), estimatedProtein: (proteinG * 0.3).round().toDouble()),
        MealPlanEntry(mealType: 'snack', description: 'Whey protein shake with a banana', estimatedCalories: (calorieTarget * 0.15).round().toDouble(), estimatedProtein: (proteinG * 0.2).round().toDouble()),
        MealPlanEntry(mealType: 'dinner', description: 'Salmon (150g) with sweet potato and salad', estimatedCalories: (calorieTarget * 0.3).round().toDouble(), estimatedProtein: (proteinG * 0.3).round().toDouble()),
      ],
    );
  }

  @override
  Future<ExerciseAdvice> getExerciseAdvice(String question, {Map<String, dynamic>? userProfile}) async {
    await Future<void>.delayed(Duration(milliseconds: 300 + _random.nextInt(300)));
    final levelStr = userProfile?['level'] as String? ?? 'intermediate';
    ExperienceLevel level; try { level = ExperienceLevel.values.byName(levelStr); } catch (_) { level = ExperienceLevel.intermediate; }
    final lowerQuestion = question.toLowerCase();
    final setsRec = level == ExperienceLevel.beginner ? '10-12' : level == ExperienceLevel.intermediate ? '12-16' : '16-20';

    if (_containsPhrase(lowerQuestion, ['chest', 'bench', 'pec', 'push'])) return ExerciseAdvice(advice: 'Chest: $setsRec sets/week across 2 sessions. Flat press for mass, incline for upper chest, flyes for stretch. Retract scapulae before pressing, control the eccentric 2-3 sec.', exercises: ['barbell_bench_press'], formTips: ['Retract and depress scapulae before pressing', 'Control the lowering for 2-3 seconds', 'Drive through feet for leg drive on bench']);
    if (_containsPhrase(lowerQuestion, ['back', 'lat', 'row', 'pull'])) return ExerciseAdvice(advice: 'Back: $setsRec sets/week. Vertical pulls for width, horizontal pulls for thickness. Do not neglect face pulls for posture.', exercises: ['pull_up', 'barbell_row'], formTips: ['Initiate pulls by squeezing shoulder blades', 'Drive elbows back, not just pulling with hands', 'Full ROM beats heavy partial reps']);
    if (_containsPhrase(lowerQuestion, ['legs', 'squat', 'quad', 'hamstring', 'glute', 'lower body'])) return ExerciseAdvice(advice: 'Legs: $setsRec sets/week split between quads, hamstrings, and glutes. Squat and deadlift variations are the foundation.', exercises: ['barbell_squat', 'romanian_deadlift'], formTips: ['Brace core before each squat rep', 'Push knees out in line with toes', 'Hit at least parallel depth']);
    return ExerciseAdvice(advice: 'For ${level.displayName.toLowerCase()} level: $setsRec sets per muscle group per week. Prioritize compound movements (squat, bench, row, overhead press, deadlift). Take most sets within 1-3 reps of failure.', exercises: ['barbell_squat', 'barbell_bench_press', 'barbell_row', 'barbell_overhead_press'], formTips: ['Warm up with 2-3 lighter sets before working weight', 'Full range of motion over heavy partial reps', 'Maintain neutral spine on all movements']);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Internal data structures
// ═══════════════════════════════════════════════════════════════════════════════

class _UserContext {
  final String? name; final double weight; final double height; final int age;
  final WorkoutGoal goal; final ExperienceLevel level; final double bmr; final double tdee;
  final double calorieTarget; final double proteinTarget; final double carbsTarget;
  final double fatsTarget; final double proteinPerKg; final int workoutDays;

  const _UserContext({this.name, required this.weight, required this.height, required this.age, required this.goal, required this.level, required this.bmr, required this.tdee, required this.calorieTarget, required this.proteinTarget, required this.carbsTarget, required this.fatsTarget, required this.proteinPerKg, required this.workoutDays});

  factory _UserContext.defaults() {
    const weight = 75.0; const height = 175.0; const age = 25;
    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    return _UserContext(weight: weight, height: height, age: age, goal: WorkoutGoal.generalFitness, level: ExperienceLevel.intermediate, bmr: bmr, tdee: bmr * 1.55, calorieTarget: 2200, proteinTarget: 150, carbsTarget: 250, fatsTarget: 70, proteinPerKg: 1.8, workoutDays: 4);
  }
}

enum _QueryIntent { calories, protein, macros, mealTiming, workoutSplit, progressiveOverload, recovery, fatLoss, muscleGain, exerciseSpecific, supplements, volume, hydration, logWorkout, logMeal, logBodyMetric, viewProgress, planWorkout, greeting, general }

class _WeightedKeyword { final String keyword; final double weight; const _WeightedKeyword(this.keyword, this.weight); }

class _ParsedWorkoutDay { final String dayLabel; final List<_ParsedExercise> exercises; final int defaultSets; final int defaultReps; DateTime? date; int duration; _ParsedWorkoutDay({required this.dayLabel, required this.exercises, this.defaultSets = 3, this.defaultReps = 12, this.duration = 60}); }

class _ParsedExercise { final String name; final double weight; final int? sets; final int? reps; const _ParsedExercise({required this.name, required this.weight, this.sets, this.reps}); }

class _ParsedFood { final String name; final double calories; final double protein; final double carbs; final double fats; final double servingSize; final String servingUnit; final String mealType; const _ParsedFood({required this.name, required this.calories, required this.protein, required this.carbs, required this.fats, required this.servingSize, required this.servingUnit, required this.mealType}); }
