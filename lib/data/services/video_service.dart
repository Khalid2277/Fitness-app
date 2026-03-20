/// A single video resource for an exercise.
class VideoResource {
  final String title;
  final String url;
  final String source;
  final String? thumbnailUrl;

  const VideoResource({
    required this.title,
    required this.url,
    required this.source,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'url': url,
        'source': source,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      };

  factory VideoResource.fromMap(Map<String, dynamic> map) => VideoResource(
        title: map['title'] as String,
        url: map['url'] as String,
        source: map['source'] as String,
        thumbnailUrl: map['thumbnailUrl'] as String?,
      );
}

// ── Abstract interface ───────────────────────────────────────────────────────

/// Contract for any video-link provider.
abstract class VideoServiceBase {
  /// Get a single video URL for an exercise.
  Future<String?> getVideoUrl(String exerciseId);

  /// Get all available video resources for an exercise.
  Future<List<VideoResource>> getVideoResources(String exerciseId);
}

// ── Curated links implementation ─────────────────────────────────────────────

/// Ships with a hardcoded set of curated links.
/// Designed to be swapped for [YouTubeVideoService] when API integration
/// is ready.
class CuratedVideoService implements VideoServiceBase {
  // Map of exerciseId → list of curated resources.
  static const Map<String, List<VideoResource>> _curatedLinks = {
    'barbell_bench_press': [
      VideoResource(
        title: 'How to Bench Press – Proper Form',
        url: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'barbell_squat': [
      VideoResource(
        title: 'How to Squat – Complete Guide',
        url: 'https://www.youtube.com/watch?v=ultWZbUMPL8',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'barbell_deadlift': [
      VideoResource(
        title: 'How to Deadlift – Step by Step',
        url: 'https://www.youtube.com/watch?v=r4MzxtBKyNE',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'barbell_overhead_press': [
      VideoResource(
        title: 'Overhead Press Technique',
        url: 'https://www.youtube.com/watch?v=2yjwXTZQDDI',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'barbell_row': [
      VideoResource(
        title: 'Barbell Row Form Guide',
        url: 'https://www.youtube.com/watch?v=kBWAon7ItDw',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'pull_up': [
      VideoResource(
        title: 'Pull-Up Progression Guide',
        url: 'https://www.youtube.com/watch?v=eGo4IYlbE5g',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'dumbbell_lateral_raise': [
      VideoResource(
        title: 'Lateral Raise – Proper Technique',
        url: 'https://www.youtube.com/watch?v=3VcKaXpzqRo',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'cable_face_pull': [
      VideoResource(
        title: 'Face Pulls for Shoulder Health',
        url: 'https://www.youtube.com/watch?v=rep-qVOkqgk',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'dumbbell_curl': [
      VideoResource(
        title: 'Dumbbell Curl Technique',
        url: 'https://www.youtube.com/watch?v=ykJmrZ5v0Oo',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'tricep_pushdown': [
      VideoResource(
        title: 'Tricep Pushdown Guide',
        url: 'https://www.youtube.com/watch?v=2-LAMcpzODU',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'leg_press': [
      VideoResource(
        title: 'Leg Press – How to Use Correctly',
        url: 'https://www.youtube.com/watch?v=IZxyjW7MPJQ',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'romanian_deadlift': [
      VideoResource(
        title: 'Romanian Deadlift Form',
        url: 'https://www.youtube.com/watch?v=jEy_czb3RKA',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'hip_thrust': [
      VideoResource(
        title: 'Hip Thrust – Complete Guide',
        url: 'https://www.youtube.com/watch?v=xDmFkJxPzeM',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
    'plank': [
      VideoResource(
        title: 'How to Plank with Perfect Form',
        url: 'https://www.youtube.com/watch?v=ASdvN_XEl_c',
        source: 'YouTube',
        thumbnailUrl: null,
      ),
    ],
  };

  @override
  Future<String?> getVideoUrl(String exerciseId) async {
    final resources = _curatedLinks[exerciseId];
    if (resources != null && resources.isNotEmpty) {
      return resources.first.url;
    }
    return null;
  }

  @override
  Future<List<VideoResource>> getVideoResources(String exerciseId) async {
    return _curatedLinks[exerciseId] ?? [];
  }

  /// List all exercise IDs that have curated videos.
  List<String> get availableExerciseIds => _curatedLinks.keys.toList();
}

// ── Placeholder for YouTube API integration ──────────────────────────────────

/// Stub for future YouTube Data API v3 integration.
///
/// To implement:
/// 1. Add googleapis / youtube_v3 dependency.
/// 2. Provide an API key.
/// 3. Search for exercise name + "form guide" or "how to".
/// 4. Map results to [VideoResource] instances.
class YouTubeVideoService implements VideoServiceBase {
  // final String _apiKey;
  // YouTubeVideoService(this._apiKey);

  @override
  Future<String?> getVideoUrl(String exerciseId) async {
    // TODO: Implement YouTube search for exercise videos.
    return null;
  }

  @override
  Future<List<VideoResource>> getVideoResources(String exerciseId) async {
    // TODO: Implement YouTube search returning multiple results.
    return [];
  }
}
