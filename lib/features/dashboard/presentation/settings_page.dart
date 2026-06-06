import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
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
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();
  bool _biometricEnabled = false;
  bool _realtimeNotifications = true;
  bool _notificationSound = true;
  bool _loading = true;
  String _role = 'mahasiswa';
  String? _avatarUrl;

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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.repository.fetchProfileSettings();
      setState(() {
        _nameController.text = profile.name;
        _nimController.text = profile.nimNip;
        _waController.text = profile.noWhatsapp;
        _avatarUrl = profile.avatarUrl;
        _biometricEnabled = profile.biometricEnabled;
        _realtimeNotifications = profile.realtimeNotificationsEnabled;
        _notificationSound = profile.notificationSoundEnabled;
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
                                GestureDetector(
                                  onTap: _pickAvatar,
                                  child: Center(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          radius: 48,
                                          backgroundColor: AppTheme.deepTeal,
                                          backgroundImage: _avatarUrl == null
                                              ? null
                                              : NetworkImage(_avatarUrl!),
                                          child: _avatarUrl == null
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 44,
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.cleanCyan,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 18,
                                              color: AppTheme.midnightNavy,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
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
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Account Security',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password baru',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _changePassword,
                                  icon: const Icon(Icons.password_rounded),
                                  label: const Text('Ganti Password'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Card(
                          child: Column(
                            children: [
                              BlocBuilder<ThemeCubit, ThemeMode>(
                                builder: (context, mode) {
                                  return SwitchListTile(
                                    value: mode == ThemeMode.dark,
                                    onChanged: (value) => context
                                        .read<ThemeCubit>()
                                        .setDarkMode(value),
                                    title: const Text('Dark Mode'),
                                    subtitle: const Text(
                                      'Midnight Navy, Dark Charcoal, dan aksen Cyan.',
                                    ),
                                  );
                                },
                              ),
                              SwitchListTile(
                                value: _biometricEnabled,
                                onChanged: (value) =>
                                    setState(() => _biometricEnabled = value),
                                title: const Text('Biometric Login'),
                                subtitle: const Text(
                                  'Aktifkan preferensi biometric login.',
                                ),
                              ),
                              SwitchListTile(
                                value: _realtimeNotifications,
                                onChanged: (value) => setState(
                                  () => _realtimeNotifications = value,
                                ),
                                title: const Text('Realtime Push Notification'),
                                subtitle: const Text(
                                  'Terima perubahan booking dan inventaris instan.',
                                ),
                              ),
                              SwitchListTile(
                                value: _notificationSound,
                                onChanged: (value) =>
                                    setState(() => _notificationSound = value),
                                title: const Text('Notification Sound'),
                                subtitle: const Text(
                                  'Aktifkan suara untuk pusat notifikasi realtime.',
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
          avatarUrl: _avatarUrl,
          biometricEnabled: _biometricEnabled,
          realtimeNotificationsEnabled: _realtimeNotifications,
          notificationSoundEnabled: _notificationSound,
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

  Future<void> _pickAvatar() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 76,
        maxWidth: 640,
      );
      if (image == null) {
        return;
      }
      final url = await widget.repository.uploadAvatar(image);
      if (!mounted) {
        return;
      }
      setState(() => _avatarUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar profil berhasil diperbarui.')),
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _changePassword() async {
    try {
      await widget.repository.updatePassword(_passwordController.text);
      _passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui.')),
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
