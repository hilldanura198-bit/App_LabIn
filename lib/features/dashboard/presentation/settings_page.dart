import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
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
      final language = prefs.getString('app_language') ?? 'id';
      setState(() {
        _language = language;
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
        _role = profile.role;
        _loading = false;
      });
    } on Object catch (error) {
      final currentUser = widget.repository.currentUser;
      final metadata = currentUser?.userMetadata ?? const <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _nameController.text = (metadata['nama'] ?? metadata['name'] ?? '-')
            .toString()
            .trim();
        _nimController.text = (metadata['nim_nip'] ?? metadata['nim'] ?? '-')
            .toString()
            .trim();
        _waController.text =
            (metadata['whatsapp_number'] ?? metadata['phone'] ?? '-')
                .toString()
                .trim();
        _emailController.text = (metadata['email'] ?? currentUser?.email ?? '-')
            .toString()
            .trim();
        _avatarUrl = null;
        _role = 'mahasiswa';
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppTheme.vibrantPurple.withValues(alpha: 0.18),
          AppTheme.electricBlue.withValues(alpha: 0.08),
          Theme.of(context).colorScheme.surface,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );

    return Scaffold(
      appBar: widget.showAppBar ? GlassAppBar(title: 'profile'.tr()) : null,
      body: Container(
        decoration: background,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth >= 720
                  ? 620.0
                  : constraints.maxWidth;
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildProfileHeader(context),
                                const SizedBox(height: 10),
                                _buildMenuCard(
                                  context,
                                  children: [
                                    _profileTile(
                                      context,
                                      icon: Icons.edit_outlined,
                                      title: _label('editProfile'),
                                      subtitle: _label('editProfileSubtitle'),
                                      onTap: _showEditProfileSheet,
                                    ),
                                    _profileTile(
                                      context,
                                      icon: Icons.language_rounded,
                                      title: _label('language'),
                                      subtitle: _language == 'id'
                                          ? 'Bahasa Indonesia'
                                          : 'English',
                                      onTap: _showLanguageSheet,
                                    ),
                                    _profileTile(
                                      context,
                                      icon: Icons.lock_outline,
                                      title: _label('changePassword'),
                                      subtitle: _label(
                                        'changePasswordSubtitle',
                                      ),
                                      onTap: _showPasswordSheet,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildMenuCard(
                                  context,
                                  children: [
                                    BlocBuilder<ThemeCubit, ThemeMode>(
                                      builder: (context, mode) {
                                        return _switchTile(
                                          context,
                                          icon: Icons.dark_mode_outlined,
                                          title: _label('darkMode'),
                                          subtitle: _label('darkModeSubtitle'),
                                          value: mode == ThemeMode.dark,
                                          onChanged: (value) {
                                            context
                                                .read<ThemeCubit>()
                                                .setDarkMode(value);
                                            _persistSettings();
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildMenuCard(
                                  context,
                                  children: [
                                    _profileTile(
                                      context,
                                      icon: Icons.logout_rounded,
                                      title: _label('logout'),
                                      subtitle: _label('logoutSubtitle'),
                                      iconColor: Colors.redAccent,
                                      onTap: _logout,
                                    ),
                                    _profileTile(
                                      context,
                                      icon: Icons.delete_outline_rounded,
                                      title: _label('deleteAccount'),
                                      subtitle: _label('deleteAccountSubtitle'),
                                      iconColor: Colors.redAccent,
                                      onTap: _showDeleteAccountDialog,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Divider(
                                  color: AppTheme.muted.withValues(alpha: 0.18),
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'Role • ${_roleLabel(_role)}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.muted.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
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
    final campus = AppTheme.campusColorsOf(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: campus.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: campus.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    child: _avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 36,
                          )
                        : ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _avatarUrl!,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 180),
                              placeholder: (context, _) => const Center(
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              errorWidget: (context, _, _) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(height: 2),
                  Text(
                    nim,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.muted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _showEditProfileSheet,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.edit_rounded, size: 20),
              tooltip: _label('editProfile'),
            ),
          ],
        ),
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

  Widget _profileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final campus = AppTheme.campusColorsOf(context);
    final color = iconColor ?? campus.primary;
    return ListTile(
      onTap: onTap,
      leading: _tileIcon(icon, color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final campus = AppTheme.campusColorsOf(context);
    return ListTile(
      leading: _tileIcon(icon, campus.secondary),
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

  String _roleLabel(String role) {
    return switch (role.toLowerCase()) {
      'kalab' => 'Kalab',
      'aslab' => 'Aslab',
      _ => 'Mahasiswa',
    };
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
                    'edit_profile'.tr(),
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
                      label: Text('edit_profile_photo'.tr()),
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
                    decoration: InputDecoration(
                      labelText: 'name'.tr(),
                      prefixIcon: const Icon(Icons.person_outline),
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
                    decoration: InputDecoration(
                      labelText: 'student_id'.tr(),
                      prefixIcon: const Icon(Icons.badge_outlined),
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
                    decoration: InputDecoration(
                      labelText: 'email'.tr(),
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
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
                    decoration: InputDecoration(
                      labelText: 'whatsapp'.tr(),
                      prefixIcon: const Icon(Icons.phone_outlined),
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
                    child: Text('save_changes'.tr()),
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
                'change_password_action'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'new_password'.tr(),
                  prefixIcon: const Icon(Icons.lock_outline),
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
                child: Text('change_password_action'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: Text('logout_confirm_title'.tr()),
          content: Text('logout_confirm_body'.tr()),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text('cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text('logout_confirm_action'.tr()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
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
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
          title: Text('delete_account_confirm_title'.tr()),
          content: Text('delete_account_confirm_body'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('delete_account_confirm_action'.tr()),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('delete_account_body'.tr())));
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
          programStudi: '',
          whatsappNumber: AppValidation.normalizeWhatsappNumber(whatsapp),
          avatarUrl: _avatarUrl,
        ),
      );
      await prefs.setString('app_language', _language);
      if (mounted && showSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings_saved'.tr())));
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
    if (!mounted) {
      return;
    }
    await context.setLocale(Locale(value));
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
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('uploading_profile_photo'.tr())),
      );
      final oldAvatarUrl = _avatarUrl;
      final url = await ProfileRepository(
        widget.repository.client,
      ).uploadProfilePicture(image);
      if (!mounted) {
        return;
      }
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(oldAvatarUrl);
      }
      setState(() => _avatarUrl = url);
      messenger.showSnackBar(
        SnackBar(content: Text('profile_photo_updated'.tr())),
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
                  title: Text(
                    'pick_from_gallery'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: _tileIcon(
                    Icons.photo_camera_outlined,
                    AppTheme.vibrantPurple,
                  ),
                  title: Text(
                    'take_from_camera'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('password_updated'.tr())));
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

  String _label(String key) {
    const id = {
      'editProfile': 'Edit Profil',
      'editProfileSubtitle': 'Nama, NIM/NIP, Email, WhatsApp',
      'language': 'Bahasa',
      'changePassword': 'Ganti Password',
      'changePasswordSubtitle': 'Perbarui kata sandi akun',
      'darkMode': 'Dark Mode',
      'darkModeSubtitle': 'Aktifkan tampilan gelap.',
      'logout': 'Keluar Akun',
      'logoutSubtitle': 'Akhiri sesi akun LabIn',
      'deleteAccount': 'Hapus Akun',
      'deleteAccountSubtitle': 'Ajukan penghapusan akun LabIn',
    };
    const en = {
      'editProfile': 'Edit Profile',
      'editProfileSubtitle': 'Name, Student ID, Email, WhatsApp',
      'language': 'Language',
      'changePassword': 'Change Password',
      'changePasswordSubtitle': 'Update your account password',
      'darkMode': 'Dark Mode',
      'darkModeSubtitle': 'Enable dark appearance.',
      'logout': 'Log Out',
      'logoutSubtitle': 'End your LabIn session',
      'deleteAccount': 'Delete Account',
      'deleteAccountSubtitle': 'Request LabIn account deletion',
    };
    return (_language == 'en' ? en : id)[key] ?? key;
  }
}
