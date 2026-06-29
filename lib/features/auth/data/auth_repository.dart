import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/auth_bloc.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient? _client;

  SupabaseClient? get client => _client;

  SupabaseClient get _supabase {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured');
    }
    return client;
  }

  String? get currentUserId => _client?.auth.currentUser?.id;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Stream<Session?> authStateChanges() {
    if (_client == null) {
      return Stream<Session?>.value(null);
    }
    return _supabase.auth.onAuthStateChange.map((state) => state.session);
  }

  Future<void> signInWithCampusSso() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.labin://login-callback',
    );
  }

  Future<bool> signInWithGoogle() {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.labin://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<String> registerMahasiswa({
    required String nama,
    required String nim,
    required String email,
    required String password,
    required XFile? ktmImage,
    required String programStudi,
  }) async {
    final existingProfile = await _supabase
        .from('profiles')
        .select('id')
        .eq('nim_nip', nim.trim())
        .maybeSingle();
    if (existingProfile != null) {
      throw Exception(
        'NIM sudah terdaftar. Silakan gunakan NIM lain atau login dengan akun yang sudah ada.',
      );
    }

    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final userId = response.user?.id;
    if (userId == null) {
      throw Exception('Registrasi berhasil, tetapi sesi user belum tersedia.');
    }

    final ktmUrl = ktmImage == null
        ? null
        : await _uploadKtmImage(userId: userId, image: ktmImage);

    await _supabase.from('profiles').upsert({
      'id': userId,
      'email': email.trim(),
      'nama': nama.trim(),
      'nim_nip': nim.trim(),
      'program_studi': programStudi.trim(),
      'role': 'mahasiswa',
      'ktm_url': ktmUrl,
    });

    await _supabase.auth.signOut();

    return userId;
  }

  Future<UserRole> fetchUserRole(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    final role = profile['role'] as String?;

    return switch (role) {
      'mahasiswa' => UserRole.mahasiswa,
      'aslab' => UserRole.aslab,
      'kalab' => UserRole.kalab,
      _ => throw Exception('Role user tidak dikenali: $role'),
    };
  }

  Future<void> signOut() async {
    if (_client == null) {
      return;
    }
    await _client.auth.signOut();
  }

  Future<String> _uploadKtmImage({
    required String userId,
    required XFile image,
  }) async {
    final extension = image.name.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final path =
        '$userId/ktm-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final bytes = await image.readAsBytes();

    await _supabase.storage
        .from('ktm')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: image.mimeType ?? 'image/$safeExtension',
          ),
        );

    return _supabase.storage.from('ktm').getPublicUrl(path);
  }
}
