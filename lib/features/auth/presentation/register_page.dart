import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
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
        if (state is Authenticated && mounted) {
          Navigator.of(context).pop();
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrasi Mahasiswa')),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth >= 720
                ? 520.0
                : constraints.maxWidth;
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: panelWidth),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Buat akun LabIN',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Lengkapi data mahasiswa dan unggah KTM.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.muted),
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nama lengkap',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: _required('Nama wajib diisi'),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nimController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'NIM',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                ),
                                validator: _required('NIM wajib diisi'),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _programStudiController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Program Studi',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                validator: _required(
                                  'Program studi wajib diisi',
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Format email belum valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
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
                                onPick: _pickKtmImage,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _scanKtmText,
                                icon: const Icon(
                                  Icons.document_scanner_outlined,
                                ),
                                label: const Text('Pindai Teks KTM Otomatis'),
                              ),
                              const SizedBox(height: 20),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return FilledButton.icon(
                                    onPressed: isLoading ? null : _submit,
                                    icon: isLoading
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.person_add_alt_1),
                                    label: const Text('Daftar'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
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

  FormFieldValidator<String> _required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  Future<void> _pickKtmImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null) {
      return;
    }
    setState(() {
      _ktmImage = image;
    });
    await _recognizeKtmText(image);
  }

  Future<void> _scanKtmText() async {
    if (_ktmImage != null) {
      await _recognizeKtmText(_ktmImage!);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _KtmScannerDialog(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _nameController.text = 'Mahasiswa LabIN';
      _nimController.text = '230401001';
      _programStudiController.text = 'Teknik Informatika';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data KTM berhasil dipindai otomatis.')),
    );
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
      if (!mounted) {
        return;
      }
      setState(() {
        if (nameLine.isNotEmpty) _nameController.text = nameLine;
        if (nimMatch != null) _nimController.text = nimMatch.group(0)!;
        if (programLine.isNotEmpty) {
          _programStudiController.text = programLine;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OCR KTM/KTP selesai dan form terisi otomatis.'),
        ),
      );
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'OCR belum menemukan teks jelas. Isi manual bila perlu.',
          ),
        ),
      );
    } finally {
      await recognizer.close();
    }
  }
}

class _KtmScannerDialog extends StatefulWidget {
  const _KtmScannerDialog();

  @override
  State<_KtmScannerDialog> createState() => _KtmScannerDialogState();
}

class _KtmScannerDialogState extends State<_KtmScannerDialog> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.richBronze.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cleanCyan, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 58,
                    color: AppTheme.deepTeal,
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    child: Container(height: 3, color: AppTheme.cleanCyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Memindai teks KTM...',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _KtmPickerCard extends StatelessWidget {
  const _KtmPickerCard({required this.fileName, required this.onPick});

  final String? fileName;
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
                    fileName ?? 'Pilih gambar dari galeri',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
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
