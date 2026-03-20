import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/progress_photo.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';

class SbProgressPhotoRepository {
  final SupabaseClient _client;

  SbProgressPhotoRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Returns all progress photo sets ordered by date descending.
  Future<List<ProgressPhotoSet>> getPhotos() async {
    final rows = await _client
        .from(SupabaseConfig.progressPhotosTable)
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false);
    return rows.map((r) => _fromRow(r)).toList();
  }

  /// Adds a new progress photo.
  ///
  /// Uploads the image file to Supabase Storage and inserts a row
  /// with the resulting public URL.
  Future<void> addPhoto({
    required DateTime date,
    required String filePath,
    String? notes,
  }) async {
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final storagePath = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    // Upload to storage bucket.
    await _client.storage
        .from(SupabaseConfig.progressPhotosBucket)
        .upload(storagePath, file);

    // Get the public URL for the uploaded file.
    final publicUrl = _client.storage
        .from(SupabaseConfig.progressPhotosBucket)
        .getPublicUrl(storagePath);

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    await _client.from(SupabaseConfig.progressPhotosTable).insert({
      'user_id': _uid,
      'date': dateStr,
      'photo_url': publicUrl,
      'storage_path': storagePath,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Deletes a progress photo row and its file from storage.
  Future<void> deletePhoto(String id) async {
    // Fetch the row first to get the storage path.
    final row = await _client
        .from(SupabaseConfig.progressPhotosTable)
        .select('storage_path')
        .eq('id', id)
        .eq('user_id', _uid)
        .maybeSingle();

    if (row != null) {
      final storagePath = row['storage_path'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        await _client.storage
            .from(SupabaseConfig.progressPhotosBucket)
            .remove([storagePath]);
      }
    }

    await _client
        .from(SupabaseConfig.progressPhotosTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }

  // ────────────────────────── Helpers ──────────────────────────────────────

  /// Converts a Supabase row into a [ProgressPhotoSet].
  static ProgressPhotoSet _fromRow(Map<String, dynamic> row) {
    // The DB stores individual photo URLs; map them into the photos map.
    final photos = <String, String>{};
    final photoUrl = row['photo_url'] as String?;
    if (photoUrl != null) {
      // Default to 'front' angle when stored as a single photo.
      final angle = row['angle'] as String? ?? 'front';
      photos[angle] = photoUrl;
    }

    return ProgressPhotoSet(
      id: row['id'] as String,
      date: DateTime.parse(row['date'] as String),
      photos: photos,
      notes: row['notes'] as String?,
      weight: (row['weight_kg'] as num?)?.toDouble(),
      bodyFatPercentage: (row['body_fat_percentage'] as num?)?.toDouble(),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }
}
