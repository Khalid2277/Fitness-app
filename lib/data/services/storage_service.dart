import 'package:hive_flutter/hive_flutter.dart';
import 'package:alfanutrition/data/models/food_item.dart';
import 'package:alfanutrition/data/models/ai_chat_message.dart';
import 'package:alfanutrition/data/models/food_search_result.dart';
import 'package:alfanutrition/data/models/progress_photo.dart';
import 'package:alfanutrition/data/models/reminder.dart';
import 'package:alfanutrition/data/models/chat_session.dart';
import 'package:alfanutrition/data/models/user_memory.dart';
import 'package:alfanutrition/data/models/body_analysis.dart';

/// Initializes Hive and opens all required storage boxes.
class StorageService {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register type adapters before opening any boxes.
    _registerAdapters();

    // Open all boxes in parallel for faster startup.
    await Future.wait([
      Hive.openBox('workouts'),
      Hive.openBox('meals'),
      Hive.openBox('body_metrics'),
      Hive.openBox('plans'),
      Hive.openBox('user_profile'),
      Hive.openBox('app_settings'),
      Hive.openBox('custom_foods'),
      Hive.openBox('food_usage'),
      Hive.openBox('food_cache'),
      Hive.openBox('foodCache'),
      Hive.openBox('ai_chat_history'),
      Hive.openBox('progress_photos'),
      Hive.openBox('reminders'),
      Hive.openBox('chat_sessions'),
      Hive.openBox('user_memories'),
      Hive.openBox('body_analyses'),
    ]);
  }

  /// Register all Hive type adapters.
  ///
  /// TypeId map:
  ///   0–18  — original models (workout, meal, body metric, plan, etc.)
  ///   19    — FoodItem
  ///   20    — AiChatMessage
  ///   21    — FoodCategory
  ///   22    — FoodSearchResult
  ///   23    — ProgressPhotoSet
  ///   24    — Reminder
  ///   25    — ChatSession
  ///   26    — UserMemory
  ///   27    — BodyAnalysis
  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(FoodItemAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(AiChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(FoodCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(FoodSearchResultAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(ProgressPhotoSetAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    if (!Hive.isAdapterRegistered(25)) {
      Hive.registerAdapter(ChatSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(26)) {
      Hive.registerAdapter(UserMemoryAdapter());
    }
    if (!Hive.isAdapterRegistered(27)) {
      Hive.registerAdapter(BodyAnalysisAdapter());
    }
  }

  /// Close all open Hive boxes (useful for testing or cleanup).
  static Future<void> close() async {
    await Hive.close();
  }

  /// Clear all data from every box.
  static Future<void> clearAll() async {
    final boxNames = [
      'workouts',
      'meals',
      'body_metrics',
      'plans',
      'user_profile',
      'app_settings',
      'custom_foods',
      'food_usage',
      'food_cache',
      'foodCache',
      'ai_chat_history',
      'progress_photos',
      'reminders',
      'chat_sessions',
      'user_memories',
      'body_analyses',
    ];
    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) {
        final box = Hive.box(name);
        await box.clear();
      }
    }
  }
}
