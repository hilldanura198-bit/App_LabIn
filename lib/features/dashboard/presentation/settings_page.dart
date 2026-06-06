import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _waController = TextEditingController();
  bool _biometricEnabled = false;
  bool _realtimeNotifications = true;
  bool _loading = true;
  String _role = 'mahasiswa';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _waController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.repository.fetchProfileSettings();
      setState(() {
        _nameController.text = profile.name;
        _nimController.text = profile.nimNip;
        _waController.text = profile.noWhatsapp;
        _biometricEnabled = profile.biometricEnabled;
        _realtimeNotifications = profile.realtimeNotificationsEnabled;
        _role = profile.role;
        _loading = false;
      });
    } on Object catch (error) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Aplikasi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Edit Profil',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _nimController,
                                  decoration: const InputDecoration(
                                    labelText: 'NIM/NIP',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _waController,
                                  decoration: const InputDecoration(
                                    labelText: 'No WhatsApp',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: _biometricEnabled,
                                onChanged: (value) =>
                                    setState(() => _biometricEnabled = value),
                                title: const Text('Pengaturan Biometrik'),
                                subtitle: const Text(
                                  'Aktifkan preferensi biometric login.',
                                ),
                              ),
                              SwitchListTile(
                                value: _realtimeNotifications,
                                onChanged: (value) => setState(
                                  () => _realtimeNotifications = value,
                                ),
                                title: const Text('Notifikasi Realtime'),
                                subtitle: const Text(
                                  'Terima perubahan booking dan inventaris instan.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Simpan Pengaturan'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<AuthBloc>().add(
                              const AuthLogoutRequested(),
                            );
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Keluar Akun'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Role aktif: $_role',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    try {
      await widget.repository.updateProfileSettings(
        ProfileSettings(
          name: _nameController.text,
          nimNip: _nimController.text,
          role: _role,
          noWhatsapp: _waController.text,
          biometricEnabled: _biometricEnabled,
          realtimeNotificationsEnabled: _realtimeNotifications,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
