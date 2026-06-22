import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/brand.dart';
import 'core/constants/supabase_credentials.dart';
import 'core/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/onboarding_page.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/aslab_dashboard_page.dart';
import 'features/dashboard/presentation/kalab_dashboard_page.dart';
import 'features/dashboard/presentation/mahasiswa_dashboard_page.dart';
import 'features/auth/presentation/terms_page.dart';

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
  await LocalNotificationService.instance.initialize();

  runApp(LabInApp(supabaseClient: supabaseClient));
}

class LabInApp extends StatelessWidget {
  const LabInApp({super.key, this.supabaseClient});

  final SupabaseClient? supabaseClient;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AuthRepository(supabaseClient),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(context.read<AuthRepository>())
                  ..add(const AuthStarted()),
          ),
          BlocProvider(create: (_) => ThemeCubit()..loadSavedTheme()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: AppBrand.name,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: const OnboardingGate(),
            );
          },
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
          final dashboard = switch (state.role) {
            UserRole.mahasiswa => const MahasiswaDashboardPage(),
            UserRole.aslab => const AslabDashboardPage(),
            UserRole.kalab => const KalabDashboardPage(),
          };
          return TermsGate(userId: state.userId, child: dashboard);
        }

        final message = state is AuthFailure ? state.message : null;
        return LoginPage(message: message);
      },
    );
  }
}

class TermsGate extends StatefulWidget {
  const TermsGate({super.key, required this.userId, required this.child});

  final String userId;
  final Widget child;

  @override
  State<TermsGate> createState() => _TermsGateState();
}

class _TermsGateState extends State<TermsGate> {
  late Future<bool> _acceptedFuture;

  @override
  void initState() {
    super.initState();
    _acceptedFuture = _readAcceptance();
  }

  @override
  void didUpdateWidget(covariant TermsGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _acceptedFuture = _readAcceptance();
    }
  }

  Future<bool> _readAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsKey(widget.userId)) ?? false;
  }

  String _termsKey(String userId) => 'terms_accepted_$userId';

  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsKey(widget.userId), true);
    if (!mounted) {
      return;
    }
    setState(() {
      _acceptedFuture = Future<bool>.value(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _acceptedFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _SplashPage();
        }
        if (snapshot.data == true) {
          return widget.child;
        }
        return TermsPage(onAccepted: _acceptTerms);
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
