import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:alfanutrition/data/models/body_analysis.dart';
import 'package:alfanutrition/data/models/progress_photo.dart';

/// AI-powered body progress analysis service.
///
/// Two operating modes:
/// - **AI Vision** (Mode A): Uses GPT-4o Vision API for photo comparison +
///   data-driven metrics when an OpenAI API key is configured.
/// - **Data-Only** (Mode B): Offline fallback that analyses weight trends,
///   body-fat changes, and workout/nutrition data without photo analysis.
class BodyAnalysisService {
  static const _baseUrl = 'https://api.openai.com/v1';
  static const _uuid = Uuid();

  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  /// The model used for vision analysis. Falls back to gpt-4o-mini if the
  /// preferred model is overridden via env.
  String get _visionModel =>
      dotenv.env['OPENAI_VISION_MODEL'] ?? 'gpt-4o';

  /// Whether the service can perform visual photo analysis.
  bool get hasVisionCapability => _apiKey.isNotEmpty;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  // ─────────────────────────── Public API ─────────────────────────────────────

  /// Analyse a photo set, optionally comparing with a previous set.
  ///
  /// [userContext] may include keys like `weight`, `goal`, `workoutsPerWeek`,
  /// `dailyCalorieTarget` for richer, personalised insights.
  Future<BodyAnalysis> analyzeProgress({
    required ProgressPhotoSet current,
    ProgressPhotoSet? previous,
    Map<String, dynamic> userContext = const {},
  }) async {
    if (hasVisionCapability) {
      try {
        return await _analyzeWithVision(current, previous, userContext);
      } catch (e) {
        debugPrint('Vision analysis failed, falling back to data-only: $e');
        return _analyzeDataOnly(current, previous, userContext);
      }
    }
    return _analyzeDataOnly(current, previous, userContext);
  }

  /// Legacy entry point kept for backward compatibility with existing callers.
  Future<BodyAnalysis> analyze({
    required ProgressPhotoSet current,
    ProgressPhotoSet? previous,
    Map<String, dynamic> userContext = const {},
  }) =>
      analyzeProgress(
        current: current,
        previous: previous,
        userContext: userContext,
      );

  // ─────────────────────────── Mode A: AI Vision ──────────────────────────────

  Future<BodyAnalysis> _analyzeWithVision(
    ProgressPhotoSet current,
    ProgressPhotoSet? previous,
    Map<String, dynamic> userContext,
  ) async {
    // 1. Encode current photos as base64 data URIs.
    final currentImages = await _encodePhotos(current.photos);
    final previousImages = previous != null
        ? await _encodePhotos(previous.photos)
        : <_ImageEntry>[];

    // 2. Build the content array for the API call.
    final contentParts = <Map<String, dynamic>>[];

    // Context description
    final contextDescription = _buildContextDescription(
      current: current,
      previous: previous,
      userContext: userContext,
    );
    contentParts.add({'type': 'text', 'text': contextDescription});

    // Attach current photos
    if (currentImages.isNotEmpty) {
      contentParts.add({
        'type': 'text',
        'text': 'CURRENT photos (taken ${_formatDate(current.date)}):',
      });
      for (final img in currentImages) {
        contentParts.add({
          'type': 'image_url',
          'image_url': {
            'url': img.dataUri,
            'detail': 'low',
          },
        });
      }
    }

    // Attach previous photos for comparison
    if (previousImages.isNotEmpty && previous != null) {
      contentParts.add({
        'type': 'text',
        'text': 'PREVIOUS photos (taken ${_formatDate(previous.date)}):',
      });
      for (final img in previousImages) {
        contentParts.add({
          'type': 'image_url',
          'image_url': {
            'url': img.dataUri,
            'detail': 'low',
          },
        });
      }
    }

    // 3. Call GPT-4o Vision API.
    final body = jsonEncode({
      'model': _visionModel,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': contentParts,
        },
      ],
      'temperature': 0.4,
      'max_completion_tokens': 1200,
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
        'OpenAI Vision API error (${response.statusCode}): $errorMsg',
      );
    }

    final data = jsonDecode(response.body);
    final raw = data['choices'][0]['message']['content'] as String? ?? '';

    // 4. Parse the structured JSON response.
    final parsed = _parseVisionResponse(raw);

    // 5. Merge with data-driven metrics.
    final dataMetrics =
        _computeDataMetrics(current: current, previous: previous);

    return BodyAnalysis(
      id: _uuid.v4(),
      photoSetId: current.id,
      comparedToSetId: previous?.id,
      analyzedAt: DateTime.now(),
      summary: parsed.summary,
      confidenceScore: parsed.confidence,
      insights: parsed.insights,
      dataMetrics: dataMetrics,
      recommendations: parsed.recommendations,
      analysisMethod: previous != null ? 'combined' : 'ai_vision',
    );
  }

  // ─────────────────────────── Mode B: Data-Only ──────────────────────────────

  Future<BodyAnalysis> _analyzeDataOnly(
    ProgressPhotoSet current,
    ProgressPhotoSet? previous,
    Map<String, dynamic> userContext,
  ) async {
    final insights = <AnalysisInsight>[];
    final recommendations = <String>[];
    final dataMetrics =
        _computeDataMetrics(current: current, previous: previous);

    final hasPrevious = previous != null;
    final summaryParts = <String>[];

    // ── Weight analysis ────────────────────────────────────────────────────
    if (hasPrevious && current.weight != null && previous.weight != null) {
      final weightChange = current.weight! - previous.weight!;
      final absDelta = weightChange.abs();
      final daysBetween =
          current.date.difference(previous.date).inDays.clamp(1, 9999);
      final weeklyRate = absDelta / (daysBetween / 7);

      String sentiment;
      String description;
      double changeScore;

      if (absDelta < 0.3) {
        sentiment = 'neutral';
        description =
            'Your weight has remained stable at ${current.weight!.toStringAsFixed(1)} kg '
            'over the past $daysBetween days.';
        changeScore = 0.0;
      } else if (weightChange < 0) {
        sentiment = 'positive';
        description =
            'You have lost ${absDelta.toStringAsFixed(1)} kg over $daysBetween days '
            '(~${weeklyRate.toStringAsFixed(1)} kg/week). '
            '${weeklyRate > 1.0 ? "This rate is faster than the recommended 0.5-1 kg/week." : "This is a healthy rate of loss."}';
        changeScore = (absDelta / 5.0).clamp(0.0, 1.0);
      } else {
        sentiment = 'neutral';
        description =
            'You have gained ${absDelta.toStringAsFixed(1)} kg over $daysBetween days '
            '(~${weeklyRate.toStringAsFixed(1)} kg/week).';
        changeScore = -(absDelta / 5.0).clamp(0.0, 1.0);
      }

      insights.add(AnalysisInsight(
        title: 'Weight Trend',
        description: description,
        category: weightChange < 0 ? 'fat_loss' : 'general',
        sentiment: sentiment,
        changeScore: changeScore,
      ));
      summaryParts.add('${description.split('.').first}.');
    } else if (current.weight != null) {
      insights.add(AnalysisInsight(
        title: 'Current Weight',
        description:
            'Your recorded weight is ${current.weight!.toStringAsFixed(1)} kg. '
            'Continue logging to track trends over time.',
        category: 'general',
        sentiment: 'neutral',
        changeScore: 0.0,
      ));
      summaryParts.add(
          'Weight recorded at ${current.weight!.toStringAsFixed(1)} kg.');
    }

    // ── Body fat analysis ──────────────────────────────────────────────────
    if (hasPrevious &&
        current.bodyFatPercentage != null &&
        previous.bodyFatPercentage != null) {
      final bfChange =
          current.bodyFatPercentage! - previous.bodyFatPercentage!;
      final absDelta = bfChange.abs();

      if (absDelta >= 0.5) {
        final isLoss = bfChange < 0;
        insights.add(AnalysisInsight(
          title: 'Body Fat Change',
          description:
              'Body fat ${isLoss ? "decreased" : "increased"} by ${absDelta.toStringAsFixed(1)}% '
              '(from ${previous.bodyFatPercentage!.toStringAsFixed(1)}% to '
              '${current.bodyFatPercentage!.toStringAsFixed(1)}%).',
          category: 'fat_loss',
          sentiment: isLoss ? 'positive' : 'negative',
          changeScore: isLoss
              ? (absDelta / 5.0).clamp(0.0, 1.0)
              : -(absDelta / 5.0).clamp(0.0, 1.0),
        ));
        summaryParts.add(
            'Body fat ${isLoss ? "down" : "up"} ${absDelta.toStringAsFixed(1)}%.');
      }
    }

    // ── Photo completeness ─────────────────────────────────────────────────
    if (current.photos.isNotEmpty) {
      insights.add(AnalysisInsight(
        title: 'Photo Coverage',
        description: current.isComplete
            ? 'All 4 angles captured. This provides the most complete view of your progress.'
            : '${current.completedAngleCount} of 4 angles captured. '
                'Missing: ${current.missingAngles.map((a) => a.displayName).join(", ")}. '
                'Complete all angles for more thorough tracking.',
        category: 'general',
        sentiment: current.isComplete ? 'positive' : 'neutral',
        changeScore: current.isComplete ? 0.5 : 0.0,
      ));
    }

    // ── Recommendations ────────────────────────────────────────────────────
    if (!hasVisionCapability) {
      recommendations.add(
        'Configure an OpenAI API key to enable AI-powered visual analysis '
        'of your progress photos.',
      );
    }

    final goal = userContext['goal'] as String?;
    if (goal != null) {
      switch (goal.toLowerCase()) {
        case 'lose weight':
        case 'fat loss':
        case 'cutting':
          recommendations.addAll([
            'Maintain a moderate calorie deficit of 300-500 kcal below maintenance.',
            'Prioritise protein intake (1.6-2.2 g/kg) to preserve muscle during a cut.',
            'Take progress photos every 2-4 weeks under consistent lighting for reliable comparison.',
          ]);
        case 'build muscle':
        case 'muscle gain':
        case 'bulking':
          recommendations.addAll([
            'Ensure a calorie surplus of 200-400 kcal above maintenance.',
            'Focus on progressive overload in your training — increase weight or reps each week.',
            'Take progress photos every 4-6 weeks; muscle changes are gradual.',
          ]);
        default:
          recommendations.addAll([
            'Stay consistent with workouts and nutrition tracking.',
            'Take progress photos every 2-4 weeks under the same lighting conditions.',
            'Log your weight regularly to identify trends over time.',
          ]);
      }
    } else {
      recommendations.addAll([
        'Take progress photos every 2-4 weeks under consistent lighting.',
        'Log your weight regularly to track trends.',
        'Set a specific goal in your profile for personalised recommendations.',
      ]);
    }

    // ── Build summary ──────────────────────────────────────────────────────
    if (summaryParts.isEmpty) {
      summaryParts.add('Progress photos logged.');
      if (!hasVisionCapability) {
        summaryParts.add('Visual analysis requires AI configuration.');
      }
      summaryParts.add(
          'Continue tracking to build a history for trend analysis.');
    }

    return BodyAnalysis(
      id: _uuid.v4(),
      photoSetId: current.id,
      comparedToSetId: previous?.id,
      analyzedAt: DateTime.now(),
      summary: summaryParts.join(' '),
      confidenceScore: hasPrevious ? 0.6 : 0.3,
      insights: insights,
      dataMetrics: dataMetrics,
      recommendations: recommendations,
      analysisMethod: 'data_only',
    );
  }

  // ─────────────────────────── Helpers ─────────────────────────────────────────

  /// Compute data-driven metrics from the two photo sets.
  Map<String, dynamic> _computeDataMetrics({
    required ProgressPhotoSet current,
    ProgressPhotoSet? previous,
  }) {
    final metrics = <String, dynamic>{};

    metrics['currentWeight'] = current.weight;
    metrics['currentBodyFat'] = current.bodyFatPercentage;
    metrics['photoCount'] = current.photos.length;
    metrics['isComplete'] = current.isComplete;

    if (previous != null) {
      final daysBetween = current.date.difference(previous.date).inDays;
      metrics['daysBetween'] = daysBetween;
      metrics['previousWeight'] = previous.weight;
      metrics['previousBodyFat'] = previous.bodyFatPercentage;

      if (current.weight != null && previous.weight != null) {
        metrics['weightChange'] = double.parse(
          (current.weight! - previous.weight!).toStringAsFixed(1),
        );
      }
      if (current.bodyFatPercentage != null &&
          previous.bodyFatPercentage != null) {
        metrics['bfChange'] = double.parse(
          (current.bodyFatPercentage! - previous.bodyFatPercentage!)
              .toStringAsFixed(1),
        );
      }
    }

    return metrics;
  }

  /// Encode a map of angle -> filePath into base64 data URIs.
  Future<List<_ImageEntry>> _encodePhotos(
      Map<String, String> photos) async {
    final entries = <_ImageEntry>[];
    for (final entry in photos.entries) {
      try {
        final file = File(entry.value);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64Str = base64Encode(bytes);
          // Detect MIME type from file extension
          final ext = entry.value.split('.').last.toLowerCase();
          final mime = switch (ext) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => 'image/jpeg',
          };
          entries.add(_ImageEntry(
            angle: entry.key,
            dataUri: 'data:$mime;base64,$base64Str',
          ));
        }
      } catch (e) {
        debugPrint('Failed to encode photo ${entry.key}: $e');
      }
    }
    return entries;
  }

  /// Build context description for the vision prompt.
  String _buildContextDescription({
    required ProgressPhotoSet current,
    ProgressPhotoSet? previous,
    Map<String, dynamic> userContext = const {},
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Analyse these body progress photos.');
    buffer.writeln();

    if (previous != null) {
      final days = current.date.difference(previous.date).inDays;
      buffer.writeln('Time between photo sets: $days days.');
    } else {
      buffer.writeln(
          'This is the first photo set — no previous comparison available.');
      buffer.writeln('Provide a baseline assessment of current physique.');
    }

    if (current.weight != null) {
      buffer.write(
          'Current weight: ${current.weight!.toStringAsFixed(1)} kg');
      if (previous?.weight != null) {
        final delta = current.weight! - previous!.weight!;
        buffer.write(
            ' (${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} kg change)');
      }
      buffer.writeln('.');
    }

    if (current.bodyFatPercentage != null) {
      buffer.write(
          'Recorded body fat: ${current.bodyFatPercentage!.toStringAsFixed(1)}%');
      if (previous?.bodyFatPercentage != null) {
        final delta =
            current.bodyFatPercentage! - previous!.bodyFatPercentage!;
        buffer.write(
            ' (${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}% change)');
      }
      buffer.writeln('.');
    }

    final goal = userContext['goal'] as String?;
    if (goal != null) buffer.writeln('User goal: $goal.');

    buffer.writeln();
    buffer.writeln(
        'Photo angles provided: ${current.completedAngles.map((a) => a.displayName).join(", ")}.');

    return buffer.toString();
  }

  /// Parse the structured JSON from the vision model response.
  _VisionResult _parseVisionResponse(String raw) {
    // Try to extract JSON from the response (model may wrap in ```json```)
    String jsonStr = raw;
    final jsonBlockMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
    if (jsonBlockMatch != null) {
      jsonStr = jsonBlockMatch.group(1)!.trim();
    } else {
      // Try to find a raw JSON object
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (objectMatch != null) {
        jsonStr = objectMatch.group(0)!;
      }
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final summary = json['summary'] as String? ?? 'Analysis complete.';
      final confidence =
          (json['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5;

      final insights = <AnalysisInsight>[];
      final rawInsights = json['insights'];
      if (rawInsights is List) {
        for (final item in rawInsights) {
          if (item is Map) {
            insights.add(
                AnalysisInsight.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      final recommendations = <String>[];
      final rawRecs = json['recommendations'];
      if (rawRecs is List) {
        for (final item in rawRecs) {
          if (item is String) recommendations.add(item);
        }
      }

      return _VisionResult(
        summary: summary,
        confidence: confidence,
        insights: insights,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('Failed to parse vision response JSON: $e');
      // Fallback: use the raw text as a summary
      return _VisionResult(
        summary: raw.length > 500 ? '${raw.substring(0, 500)}...' : raw,
        confidence: 0.3,
        insights: [
          AnalysisInsight(
            title: 'Visual Assessment',
            description: raw.length > 300 ? raw.substring(0, 300) : raw,
            category: 'general',
            sentiment: 'neutral',
          ),
        ],
        recommendations: [
          'The AI response could not be fully parsed. Try again for structured insights.',
        ],
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ─────────────────────────── System Prompt ──────────────────────────────────

  static const _systemPrompt = '''
You are a body composition analysis expert. You are analysing progress photos to help a fitness enthusiast track their body transformation.

IMPORTANT GUIDELINES:
- Be honest and specific about what you observe.
- Compare visible changes between the two photo sets when both are provided.
- Focus on: muscle definition, body shape, posture, visible fat distribution.
- Rate your confidence (0.0-1.0) based on photo quality and visibility.
- Do NOT estimate specific body fat percentages from photos — that requires callipers or DEXA.
- Do NOT make medical claims or diagnoses.
- Be encouraging but truthful — do not fabricate improvements that are not visible.

Respond ONLY with valid JSON in this exact format (no markdown, no extra text):
{
  "summary": "2-3 sentence overview of what you observe",
  "confidence": 0.75,
  "insights": [
    {
      "title": "Area of observation",
      "description": "Specific, honest observation about this area",
      "category": "muscle|fat_loss|posture|general",
      "sentiment": "positive|neutral|negative",
      "changeScore": 0.5
    }
  ],
  "recommendations": ["Actionable suggestion 1", "Actionable suggestion 2"]
}

If only one photo set is provided (no comparison), give a baseline assessment describing current visible physique characteristics. Set changeScore to 0.0 for all insights in this case.

Keep insights to 3-5 items. Keep recommendations to 2-4 items.''';
}

// ─────────────────────────── Private Types ─────────────────────────────────────

class _ImageEntry {
  final String angle;
  final String dataUri;
  const _ImageEntry({required this.angle, required this.dataUri});
}

class _VisionResult {
  final String summary;
  final double confidence;
  final List<AnalysisInsight> insights;
  final List<String> recommendations;
  const _VisionResult({
    required this.summary,
    required this.confidence,
    required this.insights,
    required this.recommendations,
  });
}
