import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_repository.dart';

enum UserRole { mahasiswa, aslab, kalab }

sealed class AuthEvent {
  const AuthEvent();
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;
}

class AuthRegisterMahasiswaRequested extends AuthEvent {
  const AuthRegisterMahasiswaRequested({
    required this.nama,
    required this.nim,
    required this.email,
    required this.password,
    required this.ktmImage,
    required this.programStudi,
  });

  final String nama;
  final String nim;
  final String email;
  final String password;
  final XFile? ktmImage;
  final String programStudi;
}

class AuthBiometricLoginRequested extends AuthEvent {
  const AuthBiometricLoginRequested();
}

class AuthCampusSsoRequested extends AuthEvent {
  const AuthCampusSsoRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated({required this.userId, required this.role});

  final String userId;
  final UserRole role;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterMahasiswaRequested>(_onRegisterMahasiswaRequested);
    on<AuthBiometricLoginRequested>(_onBiometricLoginRequested);
    on<AuthCampusSsoRequested>(_onCampusSsoRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final userId = _repository.currentUserId;
    if (userId == null) {
      emit(const Unauthenticated());
      return;
    }

    try {
      final role = await _repository.fetchUserRole(userId);
      emit(Authenticated(userId: userId, role: role));
    } on Object catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final session = await _repository.signIn(
        email: event.email,
        password: event.password,
      );
      final userId = session.user?.id;
      if (userId == null) {
        throw Exception('Login berhasil, tetapi data user belum tersedia.');
      }
      final role = await _repository.fetchUserRole(userId);
      emit(Authenticated(userId: userId, role: role));
    } on Object catch (error) {
      emit(AuthFailure(_friendlyMessage(error)));
    }
  }

  Future<void> _onRegisterMahasiswaRequested(
    AuthRegisterMahasiswaRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userId = await _repository.registerMahasiswa(
        nama: event.nama,
        nim: event.nim,
        email: event.email,
        password: event.password,
        ktmImage: event.ktmImage,
        programStudi: event.programStudi,
      );
      emit(Authenticated(userId: userId, role: UserRole.mahasiswa));
    } on Object catch (error) {
      emit(AuthFailure(_friendlyMessage(error)));
    }
  }

  Future<void> _onBiometricLoginRequested(
    AuthBiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userId = await _repository.signInWithBiometricSession();
      final role = await _repository.fetchUserRole(userId);
      emit(Authenticated(userId: userId, role: role));
    } on Object catch (error) {
      emit(AuthFailure(_friendlyMessage(error)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const Unauthenticated());
  }

  Future<void> _onCampusSsoRequested(
    AuthCampusSsoRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      const AuthFailure(
        'Tombol SSO Kampus sudah dipindahkan ke alur webview simulasi pada halaman login.',
      ),
    );
  }

  String _friendlyMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    if (raw.contains('not configured')) {
      return 'Supabase belum dikonfigurasi. Jalankan app dengan SUPABASE_URL dan SUPABASE_ANON_KEY.';
    }
    return raw;
  }
}
