import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class KalabUserManagementPage extends StatefulWidget {
  const KalabUserManagementPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<KalabUserManagementPage> createState() =>
      _KalabUserManagementPageState();
}

class _KalabUserManagementPageState extends State<KalabUserManagementPage> {
  late Future<List<UserAccountSummary>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _usersFuture = widget.repository.fetchUserAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Kontrol User'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateUserSheet,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah User'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<UserAccountSummary>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => setState(_refresh),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: _UserControlTile(
                        user: user,
                        repository: widget.repository,
                        onChanged: () => setState(_refresh),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: users.length,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateUserSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreateUserSheet(
        repository: widget.repository,
        onSaved: () => setState(_refresh),
      ),
    );
  }
}

class _UserControlTile extends StatefulWidget {
  const _UserControlTile({
    required this.user,
    required this.repository,
    required this.onChanged,
  });

  final UserAccountSummary user;
  final DashboardRepository repository;
  final VoidCallback onChanged;

  @override
  State<_UserControlTile> createState() => _UserControlTileState();
}

class _UserControlTileState extends State<_UserControlTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.deepTeal.withValues(alpha: 0.12),
              child: Icon(_iconForRole(user.role), color: AppTheme.deepTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${user.identity} | ${user.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: user.role,
              items: const [
                DropdownMenuItem(value: 'mahasiswa', child: Text('Mahasiswa')),
                DropdownMenuItem(value: 'aslab', child: Text('Aslab')),
                DropdownMenuItem(value: 'kalab', child: Text('Kalab')),
              ],
              onChanged: _busy
                  ? null
                  : (role) {
                      if (role != null && role != user.role) {
                        _updateRole(role);
                      }
                    },
            ),
            IconButton(
              tooltip: 'Hapus akun',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForRole(String role) {
    return switch (role) {
      'kalab' => Icons.admin_panel_settings,
      'aslab' => Icons.verified_user_outlined,
      _ => Icons.school_outlined,
    };
  }

  Future<void> _updateRole(String role) async {
    await _run(() {
      return widget.repository.updateUserRole(
        userId: widget.user.id,
        role: role,
      );
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: Text(
          'Profil ${widget.user.name} akan dihapus jika tidak terikat transaksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => widget.repository.deleteUserProfile(widget.user.id));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      setState(() => _busy = true);
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _CreateUserSheet extends StatefulWidget {
  const _CreateUserSheet({required this.repository, required this.onSaved});

  final DashboardRepository repository;
  final VoidCallback onSaved;

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _name = TextEditingController();
  final _identity = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'mahasiswa';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _identity.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tambah User',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _identity,
              decoration: const InputDecoration(labelText: 'NIM/NIP'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password awal'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'mahasiswa', child: Text('Mahasiswa')),
                DropdownMenuItem(value: 'aslab', child: Text('Aslab')),
                DropdownMenuItem(value: 'kalab', child: Text('Kalab')),
              ],
              onChanged: (value) =>
                  setState(() => _role = value ?? 'mahasiswa'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Buat User'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    try {
      setState(() => _saving = true);
      await widget.repository.createManagedUser(
        name: _name.text,
        identity: _identity.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      );
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}
