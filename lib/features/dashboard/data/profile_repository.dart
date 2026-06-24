import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase {
    final client = _client;
    if (client == null) {
      throw Exception('Sistem backend belum dikonfigurasi.');
    }
    return client;
  }

  Future<String> uploadProfilePicture(XFile image) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login.');
    }

    final bytes = await image.readAsBytes();
    final rawExtension = image.name.split('.').last.toLowerCase();
    final safeExtension = switch (rawExtension) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      'heif' => 'heif',
      _ => 'jpg',
    };
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
    final path =
        '$userId/profile/avatar-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: image.mimeType ?? contentType,
          ),
        );

    final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    await _supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
    return avatarUrl;
  }
}
