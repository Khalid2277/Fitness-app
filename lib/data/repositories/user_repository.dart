import 'package:hive/hive.dart';

/// Repository for user profile operations using Hive.
class UserRepository {
  static const String _boxName = 'user_profile';
  static const String _profileKey = 'profile';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  /// Save the user profile.
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final box = await _box;
    await box.put(_profileKey, profile);
  }

  /// Deep-converts Hive internal map/list types to standard Dart types.
  static dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
      );
    } else if (value is List) {
      return value.map(_deepConvert).toList();
    }
    return value;
  }

  /// Retrieve the stored user profile. Returns null if none exists.
  Future<Map<String, dynamic>?> getProfile() async {
    final box = await _box;
    final data = box.get(_profileKey);
    return data != null ? _deepConvert(data) as Map<String, dynamic> : null;
  }

  /// Check whether a profile has been created.
  Future<bool> hasProfile() async {
    final box = await _box;
    return box.containsKey(_profileKey);
  }

  /// Delete the stored profile.
  Future<void> deleteProfile() async {
    final box = await _box;
    await box.delete(_profileKey);
  }

  /// Update specific fields of the profile without overwriting everything.
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final existing = await getProfile();
    if (existing != null) {
      existing.addAll(updates);
      await saveProfile(existing);
    } else {
      await saveProfile(updates);
    }
  }
}
