import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/aslab_dashboard_page.dart';
import 'features/dashboard/presentation/kalab_dashboard_page.dart';
import 'features/dashboard/presentation/mahasiswa_dashboard_page.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseClient? supabaseClient;
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
    supabaseClient = Supabase.instance.client;
  }

  runApp(LabInApp(supabaseClient: supabaseClient));
}

class LabInApp extends StatelessWidget {
  const LabInApp({super.key, this.supabaseClient});

  final SupabaseClient? supabaseClient;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AuthRepository(supabaseClient),
      child: BlocProvider(
        create: (context) =>
            AuthBloc(context.read<AuthRepository>())..add(const AuthStarted()),
        child: MaterialApp(
          title: 'LabIN',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const _SplashPage();
        }

        if (state is Authenticated) {
          return switch (state.role) {
            UserRole.mahasiswa => const MahasiswaDashboardPage(),
            UserRole.aslab => const AslabDashboardPage(),
            UserRole.kalab => const KalabDashboardPage(),
          };
        }

        final message = state is AuthFailure ? state.message : null;
        return LoginPage(message: message);
      },
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
