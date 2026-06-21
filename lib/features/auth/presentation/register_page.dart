import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/brand.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _programStudiController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _ktmImage;
  bool _obscurePassword = true;
  String? _ktmQualityWarning;

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _programStudiController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess && mounted) {
          Navigator.of(context).pop(state.message);
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.offWhite,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth >= 720
                ? 540.0
                : constraints.maxWidth;
            final isWide = constraints.maxWidth >= 720;
            final compact = constraints.maxHeight < 760;
            final horizontalPadding = isWide ? 48.0 : 20.0;

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
                      compact ? 12 : 18,
                      horizontalPadding,
                      30,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: panelWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RegisterHero(
                            onBack: () => Navigator.of(context).maybePop(),
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 16 : 24),
                          _RegisterFormCard(
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Buat akun ${AppBrand.name}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.ink,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Lengkapi data mahasiswa dan unggah KTM.',
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
                                    if (_ktmQualityWarning != null) ...[
                                      _KtmWarningBanner(
                                        message: _ktmQualityWarning!,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    TextFormField(
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'Nama lengkap',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().length < 3) {
                                          return 'Nama wajib diisi minimal 3 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _nimController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'NIM',
                                        prefixIcon: Icon(Icons.numbers_rounded),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            !AppValidation.isValidNim(value)) {
                                          return 'NIM harus 8-15 digit angka';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _programStudiController,
                                      textInputAction: TextInputAction.next,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'Program Studi',
                                        prefixIcon: Icon(Icons.school_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().length < 3) {
                                          return 'Program studi wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
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
                                        if (!AppValidation.isValidEmail(
                                          value,
                                        )) {
                                          return 'Format email belum valid';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
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
                                    const SizedBox(height: 16),
                                    _KtmPickerCard(
                                      fileName: _ktmImage?.name,
                                      qualityWarning: _ktmQualityWarning,
                                      onPick: _pickKtmImage,
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _scanKtmText,
                                      icon: const Icon(
                                        Icons.document_scanner_outlined,
                                      ),
                                      label: const Text(
                                        'Pindai Teks KTM Otomatis',
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    BlocBuilder<AuthBloc, AuthState>(
                                      builder: (context, state) {
                                        final isLoading = state is AuthLoading;
                                        return CyberGradientButton(
                                          onPressed: isLoading ? null : _submit,
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
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.person_add_alt_1,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Daftar'),
                                                  ],
                                                ),
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
      ),
    );
  }

  Future<void> _pickKtmImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 1920,
    );
    if (image == null) {
      return;
    }
    final qualityWarning = await _assessKtmQuality(image);
    setState(() {
      _ktmImage = image;
      _ktmQualityWarning = qualityWarning;
    });
    if (qualityWarning != null) {
      messenger.showMaterialBanner(
        MaterialBanner(
          content: Text(qualityWarning),
          backgroundColor: AppTheme.richBronze.withValues(alpha: 0.18),
          leading: const Icon(Icons.warning_amber_rounded),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
              },
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }
    await _recognizeKtmText(image);
  }

  Future<void> _scanKtmText() async {
    if (_ktmImage == null) {
      await _pickKtmImage();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final warning = await _assessKtmQuality(_ktmImage!);
    setState(() => _ktmQualityWarning = warning);
    if (warning != null) {
      messenger.showMaterialBanner(
        MaterialBanner(
          content: Text(warning),
          backgroundColor: AppTheme.richBronze.withValues(alpha: 0.18),
          leading: const Icon(Icons.warning_amber_rounded),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
              },
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }
    await _recognizeKtmText(_ktmImage!);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      AuthRegisterMahasiswaRequested(
        nama: _nameController.text,
        nim: _nimController.text,
        email: _emailController.text,
        password: _passwordController.text,
        ktmImage: _ktmImage,
        programStudi: _programStudiController.text,
      ),
    );
  }

  Future<void> _recognizeKtmText(XFile image) async {
    if (image.path.isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final text = result.text;
      final nimMatch = RegExp(r'\b\d{8,12}\b').firstMatch(text);
      final lines = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.length >= 3)
          .toList();
      final nameLine = lines.firstWhere(
        (line) =>
            !RegExp(r'\d').hasMatch(line) &&
            !line.toLowerCase().contains('kartu') &&
            !line.toLowerCase().contains('mahasiswa'),
        orElse: () => '',
      );
      final programLine = lines.firstWhere(
        (line) =>
            line.toLowerCase().contains('informatika') ||
            line.toLowerCase().contains('sistem') ||
            line.toLowerCase().contains('teknik'),
        orElse: () => '',
      );
      final extractedName = _normalizeCandidate(nameLine);
      final extractedNim = nimMatch?.group(0)?.trim();
      if (!mounted) {
        return;
      }
      final didExtractSomething =
          extractedName.isNotEmpty || extractedNim != null;
      setState(() {
        if (extractedName.isNotEmpty) _nameController.text = extractedName;
        if (extractedNim != null) _nimController.text = extractedNim;
        if (programLine.isNotEmpty) {
          _programStudiController.text = programLine;
        }
        _ktmQualityWarning = didExtractSomething
            ? null
            : 'Foto belum sesuai atau kurang jelas!';
      });
      if (!didExtractSomething) {
        messenger.showMaterialBanner(
          MaterialBanner(
            content: const Text('Foto belum sesuai atau kurang jelas!'),
            backgroundColor: AppTheme.richBronze.withValues(alpha: 0.18),
            leading: const Icon(Icons.warning_amber_rounded),
            actions: [
              TextButton(
                onPressed: () {
                  messenger.hideCurrentMaterialBanner();
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('OCR KTM/KTP selesai dan form terisi otomatis.'),
        ),
      );
    } on Object catch (_) {
      if (!mounted) return;
      setState(
        () => _ktmQualityWarning = 'Foto belum sesuai atau kurang jelas!',
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Foto belum sesuai atau kurang jelas! OCR belum menemukan teks jelas.',
          ),
        ),
      );
    } finally {
      await recognizer.close();
    }
  }

  Future<String?> _assessKtmQuality(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      final data = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) {
        return 'Foto belum sesuai atau kurang jelas!';
      }
      final width = uiImage.width;
      final height = uiImage.height;
      final pixels = data.buffer.asUint8List();
      const stride = 4;
      final sampleStep = math.max(1, (width * height / 180000).ceil());

      final luminances = <double>[];
      var laplacianSum = 0.0;
      var laplacianSumSquares = 0.0;
      var laplacianCount = 0;

      int getGray(int index) {
        final r = pixels[index];
        final g = pixels[index + 1];
        final b = pixels[index + 2];
        return ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
      }

      for (var y = 1; y < height - 1; y += sampleStep) {
        for (var x = 1; x < width - 1; x += sampleStep) {
          final index = (y * width + x) * stride;
          final center = getGray(index);
          luminances.add(center.toDouble());

          final left = getGray(index - stride);
          final right = getGray(index + stride);
          final up = getGray(index - width * stride);
          final down = getGray(index + width * stride);
          final laplacian = (4 * center) - left - right - up - down;
          laplacianSum += laplacian;
          laplacianSumSquares += laplacian * laplacian;
          laplacianCount++;
        }
      }

      if (luminances.isEmpty || laplacianCount == 0) {
        return 'Foto belum sesuai atau kurang jelas!';
      }

      final meanLum =
          luminances.fold<double>(0, (sum, value) => sum + value) /
          luminances.length;
      final varianceLum =
          luminances
              .map((value) => math.pow(value - meanLum, 2).toDouble())
              .fold<double>(0, (sum, value) => sum + value) /
          luminances.length;
      final stdDevLum = math.sqrt(varianceLum);

      final meanLap = laplacianSum / laplacianCount;
      final varianceLap =
          (laplacianSumSquares / laplacianCount) - (meanLap * meanLap);

      if (stdDevLum < 28 ||
          varianceLap < 1200 ||
          meanLum < 30 ||
          meanLum > 225) {
        return 'Foto belum sesuai atau kurang jelas!';
      }
      return null;
    } on Object {
      return 'Foto belum sesuai atau kurang jelas!';
    }
  }

  String _normalizeCandidate(String value) {
    return value
        .replaceAll(RegExp(r"[^A-Za-z\s'.-]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.onBack, required this.compact});

  final VoidCallback onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        compact ? 10 : 16,
        18,
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
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          SizedBox(height: compact ? 0 : 2),
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
            'Selamat Datang',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            'Daftar sebagai mahasiswa untuk mulai memakai ${AppBrand.name}.',
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

class _RegisterFormCard extends StatelessWidget {
  const _RegisterFormCard({required this.child});

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

class _KtmWarningBanner extends StatelessWidget {
  const _KtmWarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      padding: const EdgeInsets.all(14),
      backgroundColor: Colors.redAccent.withValues(alpha: 0.10),
      leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.redAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}

class _KtmPickerCard extends StatelessWidget {
  const _KtmPickerCard({
    required this.fileName,
    required this.qualityWarning,
    required this.onPick,
  });

  final String? fileName;
  final String? qualityWarning;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.richBronze.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.richBronze.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.deepTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.upload_file_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto KTM',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName ?? 'Pilih gambar dari kamera',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                  if (qualityWarning != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      qualityWarning!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.deepTeal),
          ],
        ),
      ),
    );
  }
}
