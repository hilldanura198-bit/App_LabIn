import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/brand.dart';
import '../bloc/auth_bloc.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient? _client;
  final LocalAuthentication _localAuth = LocalAuthentication();

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

  Future<void> signInWithCampusSso() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.labin://login-callback',
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
      'nama': nama.trim(),
      'nim_nip': nim.trim(),
      'program_studi': programStudi.trim(),
      'role': 'mahasiswa',
      'ktm_url': ktmUrl,
    });

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

  Future<String> signInWithBiometricSession() async {
    final session = _supabase.auth.currentSession;
    final canAuthenticate =
        await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
    if (!canAuthenticate) {
      throw Exception('Biometric login tidak tersedia di perangkat ini.');
    }
    if (session == null || _supabase.auth.currentUser == null) {
      throw Exception(
        'Aktifkan sesi Supabase terlebih dahulu sebelum masuk biometrik.',
      );
    }

    final authenticated = await _localAuth.authenticate(
      localizedReason: 'Gunakan biometrik untuk membuka sesi ${AppBrand.name}',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
    if (!authenticated) {
      throw Exception('Autentikasi biometrik dibatalkan.');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Belum ada sesi Supabase aktif untuk biometric login.');
    }
    return userId;
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
