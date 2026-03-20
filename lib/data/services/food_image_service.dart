import 'package:alfanutrition/data/services/ai_service.dart';

/// Contract for food image analysis.
///
/// Implementations:
/// - [LocalFoodImageService] — returns a placeholder (ships by default)
/// - [ApiFoodImageService] — stub for cloud vision API integration
abstract class FoodImageService {
  /// Analyze a food photo and return estimated nutrition information.
  ///
  /// [imagePath] — local file path to the image.
  Future<FoodAnalysisResult> analyzeImage(String imagePath);
}

// ─────────────────────────────────────────────────────────────────────────────
// Local / offline implementation
// ─────────────────────────────────────────────────────────────────────────────

/// Offline placeholder that acknowledges the image but cannot analyze it.
///
/// This is the default implementation shipped with the app. It returns a
/// low-confidence placeholder result so the UI can gracefully inform the
/// user that cloud-based image analysis is required for accurate results.
class LocalFoodImageService implements FoodImageService {
  @override
  Future<FoodAnalysisResult> analyzeImage(String imagePath) async {
    // Simulate a brief processing delay for UX consistency.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    return FoodAnalysisResult(
      foodName: 'Unknown Food',
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
      confidence: 0.0,
      servingSize: 'N/A',
      imageUrl: imagePath,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cloud API implementation (stub)
// ─────────────────────────────────────────────────────────────────────────────

/// Stub for cloud-based food image analysis.
///
/// To implement:
/// 1. Choose a vision API provider:
///    - Google Cloud Vision + Vertex AI
///    - OpenAI GPT-4 Vision
///    - Clarifai Food Recognition
///    - LogMeal API (purpose-built for food)
///
/// 2. Add the HTTP client dependency (e.g., `dio` or `http`).
///
/// 3. Configure API key storage:
///    - Store API keys in secure storage (flutter_secure_storage)
///    - Never hardcode keys in source code
///    - Consider using a backend proxy to keep keys server-side
///
/// 4. Implement the [analyzeImage] method:
///    - Read the image file from [imagePath]
///    - Encode as base64 or upload to a presigned URL
///    - Send to the vision API with a food-analysis prompt
///    - Parse the response into a [FoodAnalysisResult]
///
/// 5. Handle edge cases:
///    - No food detected in image
///    - Multiple foods in one image
///    - Poor image quality / lighting
///    - Network failures (fall back to [LocalFoodImageService])
///
/// Expected API response mapping:
/// ```
/// {
///   "food_name": "Grilled Chicken Breast",
///   "confidence": 0.92,
///   "nutrition_per_serving": {
///     "calories": 165,
///     "protein_g": 31.0,
///     "carbs_g": 0.0,
///     "fat_g": 3.6
///   },
///   "serving_size": "100g"
/// }
/// ```
class ApiFoodImageService implements FoodImageService {
  // final String _apiKey;
  // final String _apiEndpoint;
  //
  // ApiFoodImageService({
  //   required String apiKey,
  //   String? apiEndpoint,
  // })  : _apiKey = apiKey,
  //       _apiEndpoint = apiEndpoint ?? 'https://api.example.com/v1/food/analyze';

  @override
  Future<FoodAnalysisResult> analyzeImage(String imagePath) async {
    // TODO: Implement cloud-based food image analysis.
    //
    // Steps:
    // 1. Read file from imagePath
    // 2. Encode / upload image
    // 3. Call vision API
    // 4. Parse nutrition response
    // 5. Return FoodAnalysisResult with real data
    //
    // On failure, consider falling back to LocalFoodImageService.

    throw UnimplementedError(
      'ApiFoodImageService requires API key configuration. '
      'Use LocalFoodImageService for offline mode.',
    );
  }
}
