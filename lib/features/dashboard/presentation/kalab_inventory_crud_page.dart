import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

class _KalabInventoryCrudPageState extends State<KalabInventoryCrudPage> {
  late Future<List<LabRoom>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = widget.repository.fetchLaboratories();
  }

  void _refreshRooms() {
    setState(() {
      _roomsFuture = widget.repository.fetchLaboratories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'CRUD Sarpras'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InventoryForm(
                      roomsFuture: _roomsFuture,
                      repository: widget.repository,
                    ),
                    const SizedBox(height: 16),
                    _RoomForm(
                      repository: widget.repository,
                      onSaved: _refreshRooms,
                    ),
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

class _InventoryForm extends StatefulWidget {
  const _InventoryForm({required this.roomsFuture, required this.repository});

  final Future<List<LabRoom>> roomsFuture;
  final DashboardRepository repository;

  @override
  State<_InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<_InventoryForm> {
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
  void dispose() {
    _name.dispose();
    _total.dispose();
    _available.dispose();
    _manualUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<LabRoom>>(
          future: widget.roomsFuture,
          builder: (context, snapshot) {
            final rooms = snapshot.data ?? const <LabRoom>[];
            _labId ??= rooms.isEmpty ? null : rooms.first.id;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  icon: Icons.inventory_2_outlined,
                  title: 'Tambah Sarana',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nama alat/bahan',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _labId,
                  decoration: const InputDecoration(labelText: 'Ruangan induk'),
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
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth >= 520
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _total,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: const [
                    DropdownMenuItem(value: 'alat', child: Text('Alat/Bahan')),
                    DropdownMenuItem(
                      value: 'ruangan',
                      child: Text('Ruangan Laboratorium'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? 'alat'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _manualUrl,
                  decoration: const InputDecoration(
                    labelText: 'Manual/PDF URL',
                  ),
                ),
                const SizedBox(height: 12),
                _ImagePickerRow(
                  imageName: _image?.name,
                  emptyLabel: 'Tambah Gambar Barang',
                  onPick: _pickImage,
                ),
                const SizedBox(height: 14),
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
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1280,
    );
    if (image != null) {
      setState(() => _image = image);
    }
  }

  Future<void> _save() async {
    try {
      setState(() => _saving = true);
      await widget.repository.createInventory(
        labId: _labId!,
        name: _name.text,
        totalStock: int.tryParse(_total.text) ?? 0,
        availableStock: int.tryParse(_available.text) ?? 0,
        type: _type,
        manualUrl: _manualUrl.text,
        image: _image,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _image = null;
        _name.clear();
        _manualUrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sarana berhasil ditambahkan.')),
      );
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

class _RoomForm extends StatefulWidget {
  const _RoomForm({required this.repository, required this.onSaved});

  final DashboardRepository repository;
  final VoidCallback onSaved;

  @override
  State<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<_RoomForm> {
  final _name = TextEditingController();
  final _picker = ImagePicker();
  late String _location;
  XFile? _image;
  bool _saving = false;

  static final _locationOptions = <String>{
    for (final lab in AppLabCatalog.labs) lab.location,
    'Gedung Rektorat Lt. 1',
    'Gedung Rektorat Lt. 2',
    'Area Luar Ruangan',
  }.toList();

  @override
  void initState() {
    super.initState();
    _location = _locationOptions.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: Icons.meeting_room_outlined,
              title: 'Tambah Ruangan Laboratorium',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama ruangan lab'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Lokasi'),
              items: _locationOptions
                  .map(
                    (location) => DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _location = value ?? _locationOptions.first;
              }),
            ),
            const SizedBox(height: 12),
            _ImagePickerRow(
              imageName: _image?.name,
              emptyLabel: 'Unggah Foto Ruangan',
              onPick: _pickImage,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Ruangan'),
            ),
          ],
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
    if (image != null) {
      setState(() => _image = image);
    }
  }

  Future<void> _save() async {
    try {
      setState(() => _saving = true);
      await widget.repository.createLaboratory(
        name: _name.text,
        location: _location,
        image: _image,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _image = null;
        _name.clear();
        _location = _locationOptions.first;
      });
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruangan laboratorium berhasil ditambahkan.'),
        ),
      );
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

class _ImagePickerRow extends StatelessWidget {
  const _ImagePickerRow({
    required this.imageName,
    required this.emptyLabel,
    required this.onPick,
  });

  final String? imageName;
  final String emptyLabel;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
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
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                imageName == null ? emptyLabel : 'Gambar dipilih: $imageName',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.deepTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
