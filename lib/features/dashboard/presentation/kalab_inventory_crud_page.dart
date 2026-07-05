import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/lab_catalog.dart';
import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class KalabInventoryCrudPage extends StatefulWidget {
  const KalabInventoryCrudPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<KalabInventoryCrudPage> createState() => _KalabInventoryCrudPageState();
}

class _KalabInventoryCrudPageState extends State<KalabInventoryCrudPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Stream<List<LabRoom>> _roomsStream;
  late final Stream<List<LabInventory>> _inventoriesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChanged);
    _roomsStream = widget.repository.watchLaboratories();
    _inventoriesStream = widget.repository.watchInventories();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Manajemen Sarpras',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: campus.primary,
          labelColor: campus.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Daftar Sarana'),
            Tab(text: 'Daftar Ruangan'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCurrentForm(context),
        backgroundColor: campus.primary,
        foregroundColor: Colors.white,
        icon: Icon(
          _tabController.index == 0
              ? Icons.inventory_2_outlined
              : Icons.meeting_room_outlined,
        ),
        label: Text(
          _tabController.index == 0 ? 'Tambah Sarana' : 'Tambah Ruangan',
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _InventoryTab(
              roomsStream: _roomsStream,
              inventoriesStream: _inventoriesStream,
              onEditInventory: (inventory) =>
                  _openInventoryForm(context, inventory: inventory),
              onDeleteInventory: (inventory) =>
                  _confirmDeleteInventory(context, inventory),
            ),
            _RoomTab(
              roomsStream: _roomsStream,
              onEditRoom: (room) => _openRoomForm(context, room: room),
              onDeleteRoom: (room) => _confirmDeleteRoom(context, room),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCurrentForm(BuildContext context) async {
    if (_tabController.index == 0) {
      await _openInventoryForm(context);
      return;
    }
    await _openRoomForm(context);
  }

  Future<void> _openInventoryForm(
    BuildContext context, {
    LabInventory? inventory,
  }) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InventoryFormSheet(
        repository: widget.repository,
        inventory: inventory,
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inventory == null
                ? 'Inventaris berhasil ditambahkan.'
                : 'Inventaris berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _openRoomForm(BuildContext context, {LabRoom? room}) async {
    final createdOrUpdated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomFormSheet(repository: widget.repository, room: room),
    );
    if (createdOrUpdated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            room == null
                ? 'Ruangan berhasil ditambahkan.'
                : 'Ruangan berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteRoom(BuildContext context, LabRoom room) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Ruangan'),
          content: Text('Hapus ruangan "${room.name}" dari database?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !context.mounted) {
      return;
    }
    try {
      final hardDeleted = await widget.repository.deleteLaboratory(room.id);
      if (!context.mounted) {
        return;
      }
      if (hardDeleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruangan berhasil dihapus.')),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Ruangan tidak bisa dihapus'),
              content: const Text(
                'Ruangan ini masih terhubung dengan data peminjaman, jadi kami ubah statusnya menjadi tutup agar tetap aman.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Mengerti'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _confirmDeleteInventory(
    BuildContext context,
    LabInventory inventory,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Sarana'),
          content: Text('Hapus sarana "${inventory.namaAlat}" dari database?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !context.mounted) {
      return;
    }
    try {
      final hardDeleted = await widget.repository.deleteInventory(inventory.id);
      if (!context.mounted) {
        return;
      }
      if (hardDeleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sarana berhasil dihapus.')),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Sarana tidak bisa dihapus'),
              content: const Text(
                'Sarana ini masih memiliki relasi riwayat peminjaman, jadi statusnya sudah diubah menjadi non-aktif.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Mengerti'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({
    required this.roomsStream,
    required this.inventoriesStream,
    required this.onEditInventory,
    required this.onDeleteInventory,
  });

  final Stream<List<LabRoom>> roomsStream;
  final Stream<List<LabInventory>> inventoriesStream;
  final ValueChanged<LabInventory> onEditInventory;
  final ValueChanged<LabInventory> onDeleteInventory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabRoom>>(
      stream: roomsStream,
      builder: (context, roomSnapshot) {
        if (roomSnapshot.hasError) {
          return Center(child: Text(roomSnapshot.error.toString()));
        }
        if (!roomSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = roomSnapshot.data ?? const <LabRoom>[];
        final roomById = {for (final room in rooms) room.id: room.name};
        return StreamBuilder<List<LabInventory>>(
          stream: inventoriesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final inventories = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryCard(
                          title: 'Daftar Sarana',
                          subtitle:
                              'Seluruh inventaris sarana tampil dalam kartu premium bergambar agar mudah dipantau.',
                          icon: Icons.inventory_2_outlined,
                          total: inventories.length,
                        ),
                        const SizedBox(height: 14),
                        if (inventories.isEmpty)
                          const _EmptyStateCard(
                            title: 'Belum ada sarana.',
                            subtitle:
                                'Tambahkan inventaris pertama melalui tombol +.',
                          )
                        else
                          ...inventories.map(
                            (inventory) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _InventoryCard(
                                inventory: inventory,
                                roomName:
                                    roomById[inventory.labId] ??
                                    inventory.labId,
                                onEdit: () => onEditInventory(inventory),
                                onDelete: () => onDeleteInventory(inventory),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.inventory,
    required this.roomName,
    required this.onEdit,
    required this.onDelete,
  });

  final LabInventory inventory;
  final String roomName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final campus = AppTheme.campusColorsOf(context);
    final imageUrl = inventory.imageUrl;
    final imageWidget = _InventoryPreview(imageUrl: imageUrl);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              campus.primary.withValues(alpha: 0.05),
              campus.secondary.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageWidget,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inventory.namaAlat,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roomName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.category_outlined,
                            label: _inventoryTypeLabel(inventory.type),
                          ),
                          _InfoChip(
                            icon: Icons.inventory_2_outlined,
                            label:
                                'Stok ${inventory.stokTersedia}/${inventory.totalStok}',
                          ),
                          _InfoChip(
                            icon: Icons.health_and_safety_outlined,
                            label: inventory.kondisi,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: inventory.totalStok <= 0
                  ? 0
                  : inventory.stokTersedia / inventory.totalStok,
              minHeight: 8,
              backgroundColor: scheme.outlineVariant.withValues(alpha: 0.35),
              color: inventory.isCritical
                  ? Colors.orangeAccent
                  : campus.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ),
      ),
    );
  }

  String _inventoryTypeLabel(String type) {
    return switch (type.toLowerCase()) {
      'ruangan' => 'Ruangan',
      'room' => 'Room',
      _ => 'Alat/Bahan',
    };
  }
}

class _RoomTab extends StatelessWidget {
  const _RoomTab({
    required this.roomsStream,
    required this.onEditRoom,
    required this.onDeleteRoom,
  });

  final Stream<List<LabRoom>> roomsStream;
  final ValueChanged<LabRoom> onEditRoom;
  final ValueChanged<LabRoom> onDeleteRoom;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabRoom>>(
      stream: roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(
                      title: 'Daftar Ruangan',
                      subtitle:
                          'Kelola daftar ruangan laboratorium dengan aksi edit dan hapus langsung.',
                      icon: Icons.meeting_room_outlined,
                      total: rooms.length,
                    ),
                    const SizedBox(height: 14),
                    if (rooms.isEmpty)
                      const _EmptyStateCard(
                        title: 'Belum ada ruangan.',
                        subtitle:
                            'Tambah ruangan pertama melalui tombol + di bawah.',
                      )
                    else
                      ...rooms.map(
                        (room) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RoomCard(
                            room: room,
                            onEdit: () => onEditRoom(room),
                            onDelete: () => onDeleteRoom(room),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  final LabRoom room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final campus = AppTheme.campusColorsOf(context);
    final imageWidget = _InventoryPreview(imageUrl: room.imageUrl);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              campus.primary.withValues(alpha: 0.05),
              campus.secondary.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageWidget,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.location,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              room.status,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: scheme.primary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                          _InfoChip(
                            icon: Icons.photo_outlined,
                            label:
                                room.imageUrl == null ||
                                    room.imageUrl!.trim().isEmpty
                                ? 'Tanpa gambar'
                                : 'Ada gambar',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryPreview extends StatelessWidget {
  const _InventoryPreview({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined),
    );
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: placeholder,
      );
    }
    final url = imageUrl!.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          fit: StackFit.expand,
          children: [
            url.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) => placeholder,
                    placeholder: (context, url) => placeholder,
                  )
                : Image.asset(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => placeholder,
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    scheme.primary.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _safeDropdownValue(String? current, List<String> options) {
  if (options.isEmpty) return null;
  if (current != null && options.contains(current)) return current;
  return options.first;
}

class _InventoryFormSheet extends StatefulWidget {
  const _InventoryFormSheet({required this.repository, this.inventory});

  final DashboardRepository repository;
  final LabInventory? inventory;

  @override
  State<_InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<_InventoryFormSheet> {
  final _name = TextEditingController();
  final _total = TextEditingController(text: '1');
  final _available = TextEditingController(text: '1');
  final _manualUrl = TextEditingController();
  final _picker = ImagePicker();
  String? _labId;
  String _type = 'alat';
  XFile? _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final inventory = widget.inventory;
    if (inventory != null) {
      _name.text = inventory.namaAlat;
      _total.text = inventory.totalStok.toString();
      _available.text = inventory.stokTersedia.toString();
      _manualUrl.text = inventory.manualUrl ?? '';
      _labId = inventory.labId;
      _type =
          _safeDropdownValue(inventory.type, const ['alat', 'ruangan']) ??
          'alat';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _available.dispose();
    _manualUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
        child: SingleChildScrollView(
          child: FutureBuilder<List<LabRoom>>(
            future: widget.repository.fetchLaboratories(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(snapshot.error.toString()),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final rooms = snapshot.data ?? const <LabRoom>[];
              final roomIds = rooms.map((room) => room.id).toList();
              _labId ??= _safeDropdownValue(widget.inventory?.labId, roomIds);
              final safeLabId = _safeDropdownValue(_labId, roomIds);
              final safeType =
                  _safeDropdownValue(_type, const ['alat', 'ruangan']) ??
                  'alat';
              _type = safeType;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHandle(
                    title: widget.inventory == null
                        ? 'Tambah Sarana'
                        : 'Edit Sarana',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nama alat/bahan',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: safeLabId,
                    decoration: const InputDecoration(labelText: 'Ruangan'),
                    items: rooms
                        .map(
                          (room) => DropdownMenuItem(
                            value: room.id,
                            child: Text(room.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _labId = value),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 560;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: wide
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth,
                            child: TextField(
                              controller: _total,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: wide
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth,
                            child: TextField(
                              controller: _available,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tersedia',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: safeType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: const [
                      DropdownMenuItem(
                        value: 'alat',
                        child: Text('Alat/Bahan'),
                      ),
                      DropdownMenuItem(
                        value: 'ruangan',
                        child: Text('Ruangan Laboratorium'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _type = value ?? 'alat'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _manualUrl,
                    decoration: const InputDecoration(
                      labelText: 'Manual/PDF URL',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PickerTile(
                    imageName: _image?.name,
                    label: 'Pilih Gambar Sarana',
                    icon: Icons.add_photo_alternate_outlined,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving || _labId == null ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Simpan Sarana'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1280,
    );
    if (image != null && mounted) {
      setState(() => _image = image);
    }
  }

  Future<void> _save() async {
    try {
      setState(() => _saving = true);
      final totalStock = int.tryParse(_total.text) ?? 0;
      final availableStock = int.tryParse(_available.text) ?? 0;
      final imageBytes = _image == null ? null : await _image!.readAsBytes();
      if (widget.inventory == null) {
        await widget.repository.createInventory(
          labId: _labId!,
          name: _name.text,
          totalStock: totalStock,
          availableStock: availableStock,
          type: _type,
          manualUrl: _manualUrl.text,
          imageBytes: imageBytes,
        );
      } else {
        await widget.repository.updateInventory(
          inventoryId: widget.inventory!.id,
          labId: _labId!,
          name: _name.text,
          totalStock: totalStock,
          availableStock: availableStock,
          type: _type,
          manualUrl: _manualUrl.text,
          imageBytes: imageBytes,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _RoomFormSheet extends StatefulWidget {
  const _RoomFormSheet({required this.repository, this.room});

  final DashboardRepository repository;
  final LabRoom? room;

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _name = TextEditingController();
  final _picker = ImagePicker();
  XFile? _image;
  bool _saving = false;
  late String _status;

  String get _initialLocation =>
      widget.room?.location ?? _locationOptions.first;

  List<String> get _locationOptions {
    final options = <String>{
      for (final lab in AppLabCatalog.labs) lab.location,
      'Gedung Rektorat Lt. 1',
      'Gedung Rektorat Lt. 2',
      'Area Luar Ruangan',
      if (widget.room?.location != null) widget.room!.location,
    }.toList();
    options.sort((a, b) => a.compareTo(b));
    return options;
  }

  late String _location = _initialLocation;

  @override
  void initState() {
    super.initState();
    _name.text = widget.room?.name ?? '';
    _status = widget.room?.status ?? 'aktif';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final locationOptions = _locationOptions;
    final safeLocation =
        _safeDropdownValue(_location, locationOptions) ?? _initialLocation;
    final safeStatus =
        _safeDropdownValue(_status, const ['aktif', 'tutup', 'non-aktif']) ??
        'aktif';
    _location = safeLocation;
    _status = safeStatus;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHandle(
                title: widget.room == null ? 'Tambah Ruangan' : 'Edit Ruangan',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nama ruangan lab',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: safeLocation,
                decoration: const InputDecoration(labelText: 'Lokasi'),
                items: locationOptions
                    .map(
                      (location) => DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _location = value ?? _initialLocation;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: safeStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                  DropdownMenuItem(value: 'tutup', child: Text('Tutup')),
                  DropdownMenuItem(
                    value: 'non-aktif',
                    child: Text('Non-aktif'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _status = value ?? 'aktif';
                }),
              ),
              const SizedBox(height: 12),
              _PickerTile(
                imageName: _image?.name,
                label: widget.room == null
                    ? 'Unggah Foto Ruangan'
                    : 'Ganti Foto Ruangan',
                icon: Icons.add_photo_alternate_outlined,
                onTap: _pickImage,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        widget.room == null
                            ? Icons.meeting_room_outlined
                            : Icons.save_outlined,
                      ),
                label: Text(
                  widget.room == null ? 'Simpan Ruangan' : 'Perbarui Ruangan',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1280,
    );
    if (image != null && mounted) {
      setState(() => _image = image);
    }
  }

  Future<void> _save() async {
    try {
      setState(() => _saving = true);
      final imageBytes = _image == null ? null : await _image!.readAsBytes();
      if (widget.room == null) {
        await widget.repository.createLaboratory(
          name: _name.text,
          location: _location,
          status: _status,
          imageBytes: imageBytes,
        );
      } else {
        await widget.repository.updateLaboratory(
          laboratoryId: widget.room!.id,
          name: _name.text,
          location: _location,
          status: _status,
          imageBytes: imageBytes,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.imageName,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String? imageName;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                imageName == null ? label : 'Gambar dipilih: $imageName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.total,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int total;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              campus.primary.withValues(alpha: 0.12),
              campus.secondary.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.campusGradientOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                '$total data',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
