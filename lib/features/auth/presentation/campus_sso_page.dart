import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validation.dart';

class CampusIdentity {
  const CampusIdentity({
    required this.name,
    required this.nim,
    required this.email,
  });

  final String name;
  final String nim;
  final String email;
}

class CampusSsoPage extends StatefulWidget {
  const CampusSsoPage({super.key});

  @override
  State<CampusSsoPage> createState() => _CampusSsoPageState();
}

class _CampusSsoPageState extends State<CampusSsoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Mahasiswa UDB');
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text('UDB Campus SSO'),
        backgroundColor: const Color(0xFF0B3B4B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BrowserChrome(
                        title: 'sso.udb.ac.id',
                        subtitle: 'Portal internal autentikasi UDB',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Masuk dengan akun kampus',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SSO simulasi ini mengembalikan NIM, nama, dan email kampus untuk dipakai di LabIN.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Nama harus diisi dengan benar';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nimController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'NIM kampus',
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Email kampus',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          if (value == null ||
                              !AppValidation.isValidEmail(value)) {
                            return 'Email kampus belum valid';
                          }
                          if (!value.toLowerCase().contains('@udb.')) {
                            return 'Gunakan email domain UDB';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Lanjutkan SSO'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sesudah valid, data identitas akan dikirim balik ke halaman login untuk dipakai otomatis.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
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
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      CampusIdentity(
        name: _nameController.text.trim(),
        nim: _nimController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
  }
}

class _BrowserChrome extends StatelessWidget {
  const _BrowserChrome({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3B4B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _Dot(color: Color(0xFFFF5F57)),
              const SizedBox(width: 8),
              const _Dot(color: Color(0xFFFFBD2E)),
              const SizedBox(width: 8),
              const _Dot(color: Color(0xFF28C840)),
              const Spacer(),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
