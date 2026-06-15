import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/validation.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _waController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();
  final _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _deviceSecurityEnabled = true;
  bool _locationEnabled = true;
  bool _realtimeNotifications = true;
  bool _notificationSound = true;
  bool _loading = true;
  String _role = 'mahasiswa';
  String? _avatarUrl;
  String _language = 'id';

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
      final prefs = await SharedPreferences.getInstance();
      final biometricSupported = await _canUseBiometricsSafely();
      final profile = await widget.repository.fetchProfileSettings();
      final currentUser = widget.repository.currentUser;
      final metadata = currentUser?.userMetadata ?? const <String, dynamic>{};
      final fallbackName = (metadata['nama'] ?? metadata['name'] ?? '')
          .toString()
          .trim();
      final fallbackNim = (metadata['nim_nip'] ?? metadata['nim'] ?? '')
          .toString()
          .trim();
      final fallbackWhatsapp =
          (metadata['whatsapp_number'] ?? metadata['phone'] ?? '')
              .toString()
              .trim();
      final language = prefs.getString('app_language') ?? 'id';
      final locationEnabled = prefs.getBool('feature_location') ?? true;
      final deviceSecurityEnabled = kIsWeb
          ? true
          : prefs.getBool('feature_device_security') ?? biometricSupported;
      setState(() {
        _language = language;
        _locationEnabled = locationEnabled;
        _deviceSecurityEnabled = deviceSecurityEnabled;
        _biometricSupported = kIsWeb ? true : biometricSupported;
        _nameController.text = profile.name.isNotEmpty
            ? profile.name
            : fallbackName;
        _nimController.text = profile.nimNip.isNotEmpty
            ? profile.nimNip
            : fallbackNim;
        _waController.text = profile.whatsappNumber.isNotEmpty
            ? profile.whatsappNumber
            : fallbackWhatsapp;
        _avatarUrl = profile.avatarUrl;
        _biometricEnabled = kIsWeb
            ? true
            : profile.biometricEnabled &&
                  deviceSecurityEnabled &&
                  biometricSupported;
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

  Future<bool> _canUseBiometricsSafely() async {
    try {
      if (kIsWeb) {
        return false;
      }
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Pengaturan Aplikasi'),
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
                        Form(
                          key: _formKey,
                          child: Card(
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
                                  const SizedBox(height: 12),
                                  Center(
                                    child: OutlinedButton.icon(
                                      onPressed: _pickAvatar,
                                      icon: const Icon(
                                        Icons.photo_camera_outlined,
                                      ),
                                      label: const Text('Edit Foto Profil'),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Edit Profil',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _nameController,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Nama wajib diisi';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Nama',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _nimController,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'NIM/NIP wajib diisi';
                                      }
                                      if (!AppValidation.isValidNim(value)) {
                                        return 'Format NIM/NIP tidak valid';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'NIM/NIP',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _waController,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Nomor WhatsApp wajib diisi';
                                      }
                                      if (!AppValidation.isValidWhatsappNumber(
                                        value,
                                      )) {
                                        return 'Format WhatsApp tidak valid';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'No WhatsApp',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.cyberGradient,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _save,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.save_outlined),
                                      label: const Text('Simpan Perubahan'),
                                    ),
                                  ),
                                ],
                              ),
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
                                  'Logo Aplikasi',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
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
                                  'General Preferences',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _language,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'id',
                                      child: Text('Bahasa Indonesia'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'en',
                                      child: Text('English'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _language = value);
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Pengaturan Bahasa',
                                    prefixIcon: Icon(Icons.language_rounded),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  value: _locationEnabled,
                                  onChanged: (value) =>
                                      setState(() => _locationEnabled = value),
                                  title: const Text('Fitur Lokasi'),
                                  subtitle: const Text(
                                    'Izinkan penggunaan lokasi untuk cek reservasi dan verifikasi akses.',
                                  ),
                                ),
                                SwitchListTile(
                                  value: _deviceSecurityEnabled,
                                  onChanged: _biometricSupported
                                      ? (value) {
                                          setState(() {
                                            _deviceSecurityEnabled = value;
                                            if (!value) {
                                              _biometricEnabled = false;
                                            }
                                          });
                                        }
                                      : null,
                                  title: const Text('Keamanan Perangkat'),
                                  subtitle: Text(
                                    _biometricSupported
                                        ? 'Sinkronkan perlindungan perangkat dan biometrik lokal.'
                                        : 'Perangkat ini belum mendukung biometrik.',
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
                                onChanged:
                                    (_biometricSupported &&
                                        (_deviceSecurityEnabled || kIsWeb))
                                    ? (value) => setState(
                                        () => _biometricEnabled = value,
                                      )
                                    : null,
                                title: const Text('Biometric Login'),
                                subtitle: Text(
                                  kIsWeb
                                      ? 'Fitur biometrik diaktifkan otomatis via browser session'
                                      : 'Aktifkan preferensi biometric login untuk perangkat lokal.',
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
    final whatsapp = _waController.text.trim();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await widget.repository.updateProfile(
        ProfileSettings(
          name: _nameController.text,
          nimNip: _nimController.text,
          role: _role,
          whatsappNumber: AppValidation.normalizeWhatsappNumber(whatsapp),
          avatarUrl: _avatarUrl,
          biometricEnabled:
              _biometricEnabled &&
              _biometricSupported &&
              _deviceSecurityEnabled,
          realtimeNotificationsEnabled: _realtimeNotifications,
          notificationSoundEnabled: _notificationSound,
        ),
      );
      await prefs.setString('app_language', _language);
      await prefs.setBool('feature_location', _locationEnabled);
      await prefs.setBool('feature_device_security', _deviceSecurityEnabled);
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
