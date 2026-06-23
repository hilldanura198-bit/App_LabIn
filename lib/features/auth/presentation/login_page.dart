import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/brand.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation.dart';
import '../bloc/auth_bloc.dart';
import '../data/auth_repository.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.message});

  final String? message;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _picker = ImagePicker();
  bool _obscurePassword = true;
  bool _isScanningCard = false;

  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showAuthMessage(widget.message!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != null && widget.message != oldWidget.message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showAuthMessage(widget.message!);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final compact = constraints.maxHeight < 700;
          final horizontalPadding = isWide ? 48.0 : 20.0;
          final panelWidth = isWide ? 460.0 : constraints.maxWidth;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FBFF), Color(0xFFEAF1FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 14 : 24,
                    horizontalPadding,
                    28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: panelWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuthHero(
                          title: 'Selamat Datang',
                          subtitle:
                              'Masuk ke ${AppBrand.name} dan kelola aktivitas lab.',
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 16 : 24),
                        _FormCard(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              compact ? 20 : 26,
                              22,
                              24,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Masuk ke ${AppBrand.name}',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.ink,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kelola aktivitas lab dengan alur yang lebih rapi.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 26),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email wajib diisi';
                                      }
                                      if (!AppValidation.isValidEmail(value)) {
                                        return 'Format email belum valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _nimController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'NIM',
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: 'Scan KTM',
                                        onPressed: _isScanningCard
                                            ? null
                                            : _scanNimCard,
                                        icon: _isScanningCard
                                            ? const SizedBox.square(
                                                dimension: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.document_scanner_outlined,
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.length < 6) {
                                        return 'Password minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 22),
                                  BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, state) {
                                      final isLoading = state is AuthLoading;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          CyberGradientButton(
                                            onPressed: isLoading
                                                ? null
                                                : _submit,
                                            borderRadius: 18,
                                            child: isLoading
                                                ? const SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.login_rounded),
                                                      SizedBox(width: 8),
                                                      Text('Email Login'),
                                                    ],
                                                  ),
                                          ),
                                          const SizedBox(height: 12),
                                          _AuthOptionButton(
                                            icon: Icons.g_mobiledata_rounded,
                                            label: 'Masuk dengan Google',
                                            onPressed: isLoading
                                                ? null
                                                : _startGoogleSso,
                                          ),
                                          const SizedBox(height: 10),
                                          _AuthOptionButton(
                                            icon: Icons.fingerprint_rounded,
                                            label: 'Masuk dengan Biometrik',
                                            onPressed: isLoading
                                                ? null
                                                : _startBiometricLogin,
                                          ),
                                          const SizedBox(height: 18),
                                          TextButton(
                                            onPressed: _openRegisterPage,
                                            child: const Text(
                                              'Daftar sebagai mahasiswa',
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    _resolveEmailFromNimIfNeeded().then((_) {
      if (!mounted) {
        return;
      }
      _submitResolved();
    });
  }

  void _submitResolved() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _resolveEmailFromNimIfNeeded() async {
    if (AppValidation.isValidEmail(_emailController.text)) {
      return;
    }
    final nim = _nimController.text.trim();
    if (nim.isEmpty) {
      return;
    }
    final email = await context.read<AuthRepository>().findEmailByNim(nim);
    if (email != null && mounted) {
      _emailController.text = email;
    }
  }

  Future<void> _scanNimCard() async {
    setState(() => _isScanningCard = true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (image == null) {
        return;
      }
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final text = result.text;
      final normalizedText = text.toLowerCase();
      final hasKtmKeyword =
          normalizedText.contains('kartu tanda mahasiswa') ||
          (normalizedText.contains('kartu') &&
              normalizedText.contains('mahasiswa'));
      final nim = RegExp(r'\b\d{8,12}\b').firstMatch(text)?.group(0);
      if (!hasKtmKeyword && nim == null) {
        throw Exception('Foto belum sesuai atau kurang jelas!');
      }
      if (!mounted) {
        return;
      }
      if (nim != null) {
        _nimController.text = nim;
      }
      await _resolveEmailFromNimIfNeeded();
      if (!mounted) {
        return;
      }
      _showPremiumSnackBar(
        'NIM berhasil dipindai. Email login otomatis diisi bila profil ditemukan.',
        Icons.verified_rounded,
      );
      if (_passwordController.text.length >= 6 &&
          AppValidation.isValidEmail(_emailController.text)) {
        _submitResolved();
      }
    } on Object catch (error) {
      if (mounted) {
        _showPremiumSnackBar(
          error.toString().contains('Foto belum sesuai')
              ? 'Foto belum sesuai atau kurang jelas!'
              : 'Scan NIM gagal. Coba foto KTM lebih jelas.',
          Icons.warning_amber_rounded,
        );
      }
    } finally {
      await recognizer.close();
      if (mounted) {
        setState(() => _isScanningCard = false);
      }
    }
  }

  void _openRegisterPage() {
    Navigator.of(context)
        .push<String>(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AuthBloc>(),
              child: const RegisterPage(),
            ),
          ),
        )
        .then((message) {
          if (!mounted || message == null) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        });
  }

  void _showAuthMessage(String message) {
    final isBiometricMessage =
        message == 'Perangkat ini tidak mendukung fitur biometrik.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: isBiometricMessage
                ? AppTheme.cyberGradient
                : LinearGradient(
                    colors: [
                      AppTheme.ink,
                      AppTheme.ink.withValues(alpha: 0.88),
                    ],
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vibrantPurple.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isBiometricMessage
                    ? Icons.fingerprint_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startGoogleSso() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masuk dengan Google',
                textAlign: TextAlign.center,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Google akan menampilkan pemilih akun dan mengembalikan profil email yang aktif.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  sheetContext,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.read<AuthBloc>().add(
                    const AuthGoogleLoginRequested(),
                  );
                },
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: const Text('Lanjutkan dengan Google'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startBiometricLogin() async {
    try {
      if (kIsWeb) {
        _showPremiumSnackBar(
          'Perangkat ini tidak mendukung fitur biometrik.',
          Icons.fingerprint_rounded,
        );
        return;
      }
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheckBiometrics || !isDeviceSupported) {
        _showPremiumSnackBar(
          'Perangkat ini tidak mendukung fitur biometrik.',
          Icons.fingerprint_rounded,
        );
        return;
      }

      var authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan biometrik untuk masuk ke ${AppBrand.name}.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      authenticated =
          authenticated ||
          await _localAuth.authenticate(
            localizedReason:
                'Biometrik gagal. Gunakan PIN/pola perangkat sebagai cadangan.',
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          );
      if (!mounted) {
        return;
      }
      if (!authenticated) {
        _showPremiumSnackBar(
          'Login biometrik dibatalkan.',
          Icons.info_outline_rounded,
        );
        return;
      }

      _showPremiumSnackBar(
        'Biometrik berhasil. Membuka dashboard...',
        Icons.verified_rounded,
      );
      context.read<AuthBloc>().add(
        const AuthBiometricLoginRequested(alreadyAuthenticated: true),
      );
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      _showPremiumSnackBar(
        'Login biometrik gagal. Coba lagi atau gunakan email.',
        Icons.warning_amber_rounded,
      );
    }
  }

  void _showPremiumSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppTheme.cyberGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vibrantPurple.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        compact ? 20 : 28,
        24,
        compact ? 22 : 30,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        gradient: LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5A67FF), Color(0xFFAF52DE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 70 : 84,
            height: compact ? 70 : 84,
            padding: EdgeInsets.all(compact ? 8 : 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/labin.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SizedBox(height: compact ? 14 : 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5ECFF)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricBlue.withValues(alpha: 0.13),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthOptionButton extends StatelessWidget {
  const _AuthOptionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.ink,
          side: const BorderSide(color: Color(0xFFE0E7FF)),
          textStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
