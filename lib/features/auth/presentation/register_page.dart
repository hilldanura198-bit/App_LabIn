import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _ktmImage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
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
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Lengkapi data mahasiswa dan unggah KTM.',
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
          color: const Color(0xFFEFFAF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCDE9DF)),
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
