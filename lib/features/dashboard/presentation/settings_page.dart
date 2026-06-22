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
import '../data/profile_repository.dart';
import 'widgets/glass_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });

  final DashboardRepository repository;
  final bool showAppBar;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
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
    _emailController.dispose();
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
      final fallbackEmail = (metadata['email'] ?? currentUser?.email ?? '')
          .toString()
          .trim();
      final language = prefs.getString('app_language') ?? profile.appLanguage;
      final locationEnabled =
          prefs.getBool('feature_location') ?? profile.locationEnabled;
      final deviceSecurityEnabled = kIsWeb
          ? true
          : prefs.getBool('feature_device_security') ??
                profile.deviceSecurityEnabled;
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
        _emailController.text = profile.email.isNotEmpty
            ? profile.email
            : fallbackEmail;
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
      appBar: widget.showAppBar ? const GlassAppBar(title: 'Profil') : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.vibrantPurple.withValues(alpha: 0.18),
                    AppTheme.electricBlue.withValues(alpha: 0.08),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(context),
                          const SizedBox(height: 16),
                          _buildMenuCard(
                            context,
                            children: [
                              _profileTile(
                                icon: Icons.edit_outlined,
                                title: 'Edit Profil',
                                subtitle: 'Nama, NIM/NIP, Email, WhatsApp',
                                onTap: _showEditProfileSheet,
                              ),
                              _profileTile(
                                icon: Icons.language_rounded,
                                title: 'Bahasa',
                                subtitle: _language == 'id'
                                    ? 'Bahasa Indonesia'
                                    : 'English',
                                onTap: _showLanguageSheet,
                              ),
                              _profileTile(
                                icon: Icons.lock_outline,
                                title: 'Ganti Password',
                                subtitle: 'Perbarui kata sandi akun',
                                onTap: _showPasswordSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildMenuCard(
                            context,
                            children: [
                              _switchTile(
                                icon: Icons.location_on_outlined,
                                title: 'Fitur Lokasi',
                                subtitle:
                                    'Izinkan lokasi untuk cek reservasi dan akses.',
                                value: _locationEnabled,
                                onChanged: (value) => _updatePreference(
                                  () => _locationEnabled = value,
                                ),
                              ),
                              _switchTile(
                                icon: Icons.verified_user_outlined,
                                title: 'Keamanan Perangkat',
                                subtitle: _biometricSupported
                                    ? 'Sinkronkan perlindungan perangkat.'
                                    : 'Perangkat belum mendukung biometrik.',
                                value: _deviceSecurityEnabled,
                                onChanged: _biometricSupported
                                    ? (value) {
                                        _updatePreference(() {
                                          _deviceSecurityEnabled = value;
                                          if (!value) {
                                            _biometricEnabled = false;
                                          }
                                        });
                                      }
                                    : null,
                              ),
                              BlocBuilder<ThemeCubit, ThemeMode>(
                                builder: (context, mode) {
                                  return _switchTile(
                                    icon: Icons.dark_mode_outlined,
                                    title: 'Dark Mode',
                                    subtitle: 'Aktifkan tampilan gelap.',
                                    value: mode == ThemeMode.dark,
                                    onChanged: (value) {
                                      context.read<ThemeCubit>().setDarkMode(
                                        value,
                                      );
                                      _persistSettings();
                                    },
                                  );
                                },
                              ),
                              _switchTile(
                                icon: Icons.fingerprint_rounded,
                                title: 'Biometric Login',
                                subtitle: kIsWeb
                                    ? 'Aktif via browser session.'
                                    : 'Preferensi biometrik lokal.',
                                value: _biometricEnabled,
                                onChanged:
                                    (_biometricSupported &&
                                        (_deviceSecurityEnabled || kIsWeb))
                                    ? (value) => _updatePreference(
                                        () => _biometricEnabled = value,
                                      )
                                    : null,
                              ),
                              _switchTile(
                                icon: Icons.notifications_active_outlined,
                                title: 'Realtime Notification',
                                subtitle:
                                    'Update booking dan inventaris instan.',
                                value: _realtimeNotifications,
                                onChanged: (value) => _updatePreference(
                                  () => _realtimeNotifications = value,
                                ),
                              ),
                              _switchTile(
                                icon: Icons.volume_up_outlined,
                                title: 'Notification Sound',
                                subtitle: 'Suara untuk notifikasi realtime.',
                                value: _notificationSound,
                                onChanged: (value) => _updatePreference(
                                  () => _notificationSound = value,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildMenuCard(
                            context,
                            children: [
                              _profileTile(
                                icon: Icons.logout_rounded,
                                title: 'Keluar Akun',
                                subtitle: 'Akhiri sesi akun LabIn',
                                iconColor: Colors.redAccent,
                                onTap: _logout,
                              ),
                              _profileTile(
                                icon: Icons.delete_outline_rounded,
                                title: 'Hapus Akun',
                                subtitle: 'Ajukan penghapusan akun LabIn',
                                iconColor: Colors.redAccent,
                                onTap: _showDeleteAccountDialog,
                              ),
                            ],
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
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final name = _nameController.text.trim().isEmpty
        ? 'Pengguna LabIn'
        : _nameController.text.trim();
    final nim = _nimController.text.trim().isEmpty
        ? 'Lengkapi profil Anda'
        : _nimController.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cyberGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantPurple.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  backgroundImage: _avatarUrl == null
                      ? null
                      : NetworkImage(_avatarUrl!),
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 34)
                      : null,
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: AppTheme.electricBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nim,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: _showEditProfileSheet,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppTheme.electricBlue;
    return ListTile(
      onTap: onTap,
      leading: _tileIcon(icon, color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: _tileIcon(icon, AppTheme.vibrantPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _tileIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }

  void _showEditProfileSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            8,
            22,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Profil',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Edit Foto Profil'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
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
                      if (value == null || value.trim().isEmpty) {
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!AppValidation.isValidEmail(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _waController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor WhatsApp wajib diisi';
                      }
                      if (!AppValidation.isValidWhatsappNumber(value)) {
                        return 'Format WhatsApp tidak valid';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'No WhatsApp',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  CyberGradientButton(
                    onPressed: () async {
                      final saved = await _save();
                      if (saved && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: _tileIcon(
                  Icons.translate_rounded,
                  AppTheme.electricBlue,
                ),
                title: const Text('Bahasa Indonesia'),
                trailing: _language == 'id'
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  _changeLanguage('id');
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: _tileIcon(
                  Icons.translate_rounded,
                  AppTheme.vibrantPurple,
                ),
                title: const Text('English'),
                trailing: _language == 'en'
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  _changeLanguage('en');
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            8,
            22,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ganti Password',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password baru',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              CyberGradientButton(
                onPressed: () async {
                  final changed = await _changePassword();
                  if (changed && sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
                child: const Text('Ganti Password'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _logout() {
    if (widget.showAppBar && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Akun'),
          content: const Text(
            'Penghapusan akun membutuhkan verifikasi admin agar data peminjaman dan riwayat lab tetap aman.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ajukan'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permintaan hapus akun dikirim untuk diverifikasi admin.',
        ),
      ),
    );
  }

  void _updatePreference(VoidCallback update) {
    setState(update);
    _persistSettings();
  }

  Future<bool> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }
    final saved = await _persistSettings(showSnackBar: true);
    if (saved) {
      await _load();
    }
    return saved;
  }

  Future<bool> _persistSettings({bool showSnackBar = false}) async {
    final whatsapp = _waController.text.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await widget.repository.updateProfile(
        ProfileSettings(
          name: _nameController.text,
          nimNip: _nimController.text,
          email: _emailController.text,
          role: _role,
          whatsappNumber: AppValidation.normalizeWhatsappNumber(whatsapp),
          avatarUrl: _avatarUrl,
          biometricEnabled:
              _biometricEnabled &&
              _biometricSupported &&
              _deviceSecurityEnabled,
          realtimeNotificationsEnabled: _realtimeNotifications,
          notificationSoundEnabled: _notificationSound,
          appLanguage: _language,
          locationEnabled: _locationEnabled,
          deviceSecurityEnabled: _deviceSecurityEnabled,
        ),
      );
      await prefs.setString('app_language', _language);
      await prefs.setBool('feature_location', _locationEnabled);
      await prefs.setBool('feature_device_security', _deviceSecurityEnabled);
      if (mounted && showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan.')),
        );
      }
      return true;
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return false;
    }
  }

  Future<void> _changeLanguage(String value) async {
    setState(() => _language = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', value);
    await _persistSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value == 'id'
                ? 'Bahasa diubah ke Bahasa Indonesia.'
                : 'Language changed to English.',
          ),
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final source = await _chooseAvatarSource();
    if (source == null) {
      return;
    }
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 76,
        maxWidth: 640,
      );
      if (image == null) {
        return;
      }
      final url = await ProfileRepository(
        widget.repository.client,
      ).uploadProfilePicture(image);
      if (!mounted) {
        return;
      }
      setState(() => _avatarUrl = url);
      await _load();
      if (!mounted) {
        return;
      }
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

  Future<ImageSource?> _chooseAvatarSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: _tileIcon(
                    Icons.photo_library_outlined,
                    AppTheme.electricBlue,
                  ),
                  title: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: _tileIcon(
                    Icons.photo_camera_outlined,
                    AppTheme.vibrantPurple,
                  ),
                  title: const Text(
                    'Ambil dari Kamera',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _changePassword() async {
    try {
      await widget.repository.updatePassword(_passwordController.text);
      _passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui.')),
        );
      }
      return true;
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return false;
    }
  }
}
