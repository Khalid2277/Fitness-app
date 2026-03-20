import 'dart:convert';

import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnalysisInsight
// ─────────────────────────────────────────────────────────────────────────────

/// A single insight from a body progress analysis.
class AnalysisInsight {
  final String title;
  final String description;
  final String category; // 'muscle', 'fat_loss', 'posture', 'general'
  final String sentiment; // 'positive', 'neutral', 'negative'
  final double? changeScore; // -1.0 to 1.0

  const AnalysisInsight({
    required this.title,
    required this.description,
    this.category = 'general',
    this.sentiment = 'neutral',
    this.changeScore,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'sentiment': sentiment,
        'changeScore': changeScore,
      };

  factory AnalysisInsight.fromJson(Map<String, dynamic> json) =>
      AnalysisInsight(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        sentiment: json['sentiment'] as String? ?? 'neutral',
        changeScore: (json['changeScore'] as num?)?.toDouble(),
      );

  AnalysisInsight copyWith({
    String? title,
    String? description,
    String? category,
    String? sentiment,
    double? changeScore,
  }) {
    return AnalysisInsight(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      sentiment: sentiment ?? this.sentiment,
      changeScore: changeScore ?? this.changeScore,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BodyAnalysis — typeId 27
// ─────────────────────────────────────────────────────────────────────────────

/// Result of an AI-powered body progress analysis.
///
/// Stores insights from either GPT-4 Vision analysis of progress photos or
/// data-only analysis from weight/measurement trends.
class BodyAnalysis {
  final String id;
  final String photoSetId;
  final String? comparedToSetId;
  final DateTime analyzedAt;

  // Overall assessment
  final String summary;
  final double confidenceScore; // 0.0–1.0

  // Detailed insights
  final List<AnalysisInsight> insights;

  // Data-driven metrics (e.g. weightChange, bfChange, daysBetween)
  final Map<String, dynamic> dataMetrics;

  // Recommendations
  final List<String> recommendations;

  // 'ai_vision', 'data_only', 'combined'
  final String analysisMethod;

  const BodyAnalysis({
    required this.id,
    required this.photoSetId,
    this.comparedToSetId,
    required this.analyzedAt,
    required this.summary,
    this.confidenceScore = 0.0,
    this.insights = const [],
    this.dataMetrics = const {},
    this.recommendations = const [],
    this.analysisMethod = 'data_only',
  });

  // ──────────────────────── Serialization ───────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'photoSetId': photoSetId,
        'comparedToSetId': comparedToSetId,
        'analyzedAt': analyzedAt.toIso8601String(),
        'summary': summary,
        'confidenceScore': confidenceScore,
        'insights': insights.map((i) => i.toJson()).toList(),
        'dataMetrics': dataMetrics,
        'recommendations': recommendations,
        'analysisMethod': analysisMethod,
      };

  factory BodyAnalysis.fromJson(Map<String, dynamic> json) {
    final rawInsights = json['insights'];
    final insightList = <AnalysisInsight>[];
    if (rawInsights is List) {
      for (final item in rawInsights) {
        if (item is Map) {
          insightList
              .add(AnalysisInsight.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawRecs = json['recommendations'];
    final recList = <String>[];
    if (rawRecs is List) {
      for (final item in rawRecs) {
        if (item is String) recList.add(item);
      }
    }

    final rawMetrics = json['dataMetrics'];
    final metrics = rawMetrics is Map
        ? Map<String, dynamic>.from(rawMetrics)
        : <String, dynamic>{};

    return BodyAnalysis(
      id: json['id'] as String? ?? '',
      photoSetId: json['photoSetId'] as String? ?? '',
      comparedToSetId: json['comparedToSetId'] as String?,
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'] as String)
          : DateTime.now(),
      summary: json['summary'] as String? ?? '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      insights: insightList,
      dataMetrics: metrics,
      recommendations: recList,
      analysisMethod: json['analysisMethod'] as String? ?? 'data_only',
    );
  }

  // ──────────────────────── copyWith ────────────────────────────────────────

  BodyAnalysis copyWith({
    String? id,
    String? photoSetId,
    String? comparedToSetId,
    DateTime? analyzedAt,
    String? summary,
    double? confidenceScore,
    List<AnalysisInsight>? insights,
    Map<String, dynamic>? dataMetrics,
    List<String>? recommendations,
    String? analysisMethod,
  }) {
    return BodyAnalysis(
      id: id ?? this.id,
      photoSetId: photoSetId ?? this.photoSetId,
      comparedToSetId: comparedToSetId ?? this.comparedToSetId,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      summary: summary ?? this.summary,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      insights: insights ?? this.insights,
      dataMetrics: dataMetrics ?? this.dataMetrics,
      recommendations: recommendations ?? this.recommendations,
      analysisMethod: analysisMethod ?? this.analysisMethod,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hive TypeAdapter — typeId 27
// ─────────────────────────────────────────────────────────────────────────────

class BodyAnalysisAdapter extends TypeAdapter<BodyAnalysis> {
  @override
  final int typeId = 27;

  @override
  BodyAnalysis read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();

    // insights is stored as a JSON-encoded string
    final rawInsights = map['insights'];
    List<dynamic> insightsList;
    if (rawInsights is String) {
      insightsList = jsonDecode(rawInsights) as List<dynamic>;
    } else if (rawInsights is List) {
      insightsList = rawInsights;
    } else {
      insightsList = [];
    }

    // dataMetrics is stored as a JSON-encoded string
    final rawMetrics = map['dataMetrics'];
    Map<String, dynamic> metricsMap;
    if (rawMetrics is String) {
      metricsMap =
          Map<String, dynamic>.from(jsonDecode(rawMetrics) as Map);
    } else if (rawMetrics is Map) {
      metricsMap = Map<String, dynamic>.from(rawMetrics);
    } else {
      metricsMap = {};
    }

    // recommendations is stored as a JSON-encoded string
    final rawRecs = map['recommendations'];
    List<String> recsList;
    if (rawRecs is String) {
      recsList = (jsonDecode(rawRecs) as List).cast<String>();
    } else if (rawRecs is List) {
      recsList = rawRecs.cast<String>();
    } else {
      recsList = [];
    }

    return BodyAnalysis.fromJson({
      'id': map['id'],
      'photoSetId': map['photoSetId'],
      'comparedToSetId': map['comparedToSetId'],
      'analyzedAt': map['analyzedAt'],
      'summary': map['summary'],
      'confidenceScore': map['confidenceScore'],
      'insights': insightsList,
      'dataMetrics': metricsMap,
      'recommendations': recsList,
      'analysisMethod': map['analysisMethod'],
    });
  }

  @override
  void write(BinaryWriter writer, BodyAnalysis obj) {
    final json = obj.toJson();
    // Serialize complex types as JSON strings for reliable Hive storage
    json['insights'] = jsonEncode(obj.insights.map((i) => i.toJson()).toList());
    json['dataMetrics'] = jsonEncode(obj.dataMetrics);
    json['recommendations'] = jsonEncode(obj.recommendations);
    writer.writeMap(json);
  }
}
