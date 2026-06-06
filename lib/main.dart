import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/constants/supabase_credentials.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/onboarding_page.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/aslab_dashboard_page.dart';
import 'features/dashboard/presentation/kalab_dashboard_page.dart';
import 'features/dashboard/presentation/mahasiswa_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseClient? supabaseClient;
  if (SupabaseCredentials.isConfigured) {
    await Supabase.initialize(
      url: SupabaseCredentials.url,
      publishableKey: SupabaseCredentials.anonKey,
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
          home: const OnboardingGate(),
        ),
      ),
    );
  }
}

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return const AuthGate();
    }
    return OnboardingPage(onFinished: () => setState(() => _finished = true));
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
