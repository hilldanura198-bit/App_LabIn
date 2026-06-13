import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validation.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'booking_success_page.dart';
import 'widgets/glass_app_bar.dart';

class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _nameController = TextEditingController();
  final _waController = TextEditingController();
  int _step = 0;
  List<LabRoom> _labs = const [];
  List<LabInventory> _inventories = const [];
  String? _selectedLabId;
  String? _selectedDeskNo;
  final _selectedItems = <String, BookingItemDraft>{};
  final _consumableNotesController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _waController.dispose();
    _consumableNotesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final labs = await widget.repository.fetchLaboratories();
      final inventories = await widget.repository.watchInventories().first;
      setState(() {
        _labs = labs;
        _inventories = inventories;
        _selectedLabId = labs.isEmpty ? null : labs.first.id;
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
      appBar: const GlassAppBar(title: 'Formulir Peminjaman'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stepper(
                currentStep: _step,
                onStepContinue: _submitting ? null : _continue,
                onStepCancel: _step == 0 || _submitting
                    ? null
                    : () => setState(() => _step--),
                controlsBuilder: (context, details) {
                  final last = _step == 3;
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CyberGradientButton(
                            onPressed: details.onStepContinue,
                            child: _submitting && last
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(last ? 'Kirim Pengajuan' : 'Lanjut'),
                          ),
                        ),
                        if (_step > 0) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Kembali'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Identitas & No WhatsApp'),
                    isActive: _step >= 0,
                    content: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama peminjam',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _waController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No WhatsApp',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Pilih Ruangan/Laboratorium'),
                    isActive: _step >= 1,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLabId,
                          items: _labs
                              .map(
                                (lab) => DropdownMenuItem(
                                  value: lab.id,
                                  child: Text('${lab.name} - ${lab.location}'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedLabId = value),
                          decoration: const InputDecoration(
                            labelText: 'Laboratorium',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _VirtualTourDeskGrid(
                          selectedDeskNo: _selectedDeskNo,
                          onSelected: (deskNo) =>
                              setState(() => _selectedDeskNo = deskNo),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Pilih Barang Tidak Habis Pakai'),
                    isActive: _step >= 2,
                    content: _InventoryChecklist(
                      inventories: _inventories
                          .where((item) => item.labId == _selectedLabId)
                          .toList(),
                      selectedItems: _selectedItems,
                      onToggle: _toggleItem,
                    ),
                  ),
                  Step(
                    title: const Text('Konfirmasi & Barang Habis Pakai'),
                    isActive: _step >= 3,
                    content: _ConsumableReviewStep(
                      selectedLab: _selectedLab,
                      selectedDeskNo: _selectedDeskNo,
                      selectedItems: _selectedItems.values.toList(),
                      consumableNotesController: _consumableNotesController,
                      onQuantityChanged: _updateItemQuantity,
                      onRemoveItem: _removeItem,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  LabRoom? get _selectedLab {
    for (final lab in _labs) {
      if (lab.id == _selectedLabId) {
        return lab;
      }
    }
    return null;
  }

  void _toggleItem(LabInventory inventory, bool selected) {
    setState(() {
      if (selected) {
        _selectedItems[inventory.id] = BookingItemDraft(
          inventory: inventory,
          quantity: 1,
        );
      } else {
        _selectedItems.remove(inventory.id);
      }
    });
  }

  void _updateItemQuantity(LabInventory inventory, int quantity) {
    setState(() {
      _selectedItems[inventory.id] = BookingItemDraft(
        inventory: inventory,
        quantity: quantity.clamp(1, inventory.stokTersedia),
      );
    });
  }

  void _removeItem(LabInventory inventory) {
    setState(() => _selectedItems.remove(inventory.id));
  }

  Future<void> _continue() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    if (_selectedLabId == null) {
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        _waController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan No WhatsApp wajib diisi.')),
      );
      setState(() => _step = 0);
      return;
    }
    final whatsapp = _waController.text.trim();
    if (!AppValidation.isValidWhatsappNumber(whatsapp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format No WhatsApp belum valid.')),
      );
      return;
    }
    try {
      setState(() => _submitting = true);
      final booking = await widget.repository.createMultiStepBooking(
        labId: _selectedLabId!,
        whatsappNumber: AppValidation.normalizeWhatsappNumber(whatsapp),
        tanggalPinjam: DateTime.now().add(const Duration(days: 1)),
        deskNo: _selectedDeskNo,
        items: _selectedItems.values.toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan multi-step berhasil dikirim.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BookingSuccessPage(booking: booking)),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _VirtualTourDeskGrid extends StatelessWidget {
  const _VirtualTourDeskGrid({
    required this.selectedDeskNo,
    required this.onSelected,
  });

  final String? selectedDeskNo;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final desks = List.generate(18, (index) => 'M-${index + 1}');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Interactive Lab Virtual Tour',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih nomor meja komputer spesifik untuk sesi praktikum.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 430 ? 6 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: desks.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final deskNo = desks[index];
                    final selected = selectedDeskNo == deskNo;
                    final occupied = index == 2 || index == 9 || index == 14;
                    return InkWell(
                      onTap: occupied ? null : () => onSelected(deskNo),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: occupied
                              ? AppTheme.richBronze.withValues(alpha: 0.22)
                              : selected
                              ? AppTheme.cleanCyan
                              : AppTheme.richBronze.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppTheme.deepTeal
                                : AppTheme.richBronze.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.desktop_windows_outlined,
                              color: selected
                                  ? AppTheme.midnightNavy
                                  : AppTheme.deepTeal,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deskNo,
                              style: TextStyle(
                                color: selected
                                    ? AppTheme.midnightNavy
                                    : AppTheme.deepTeal,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryChecklist extends StatelessWidget {
  const _InventoryChecklist({
    required this.inventories,
    required this.selectedItems,
    required this.onToggle,
  });

  final List<LabInventory> inventories;
  final Map<String, BookingItemDraft> selectedItems;
  final void Function(LabInventory inventory, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    if (inventories.isEmpty) {
      return const Text('Tidak ada inventaris untuk lab ini.');
    }
    return Column(
      children: inventories
          .map(
            (inventory) => CheckboxListTile(
              value: selectedItems.containsKey(inventory.id),
              onChanged: inventory.isAvailable
                  ? (value) => onToggle(inventory, value ?? false)
                  : null,
              title: Text(inventory.namaAlat),
              subtitle: Text('Stok ${inventory.stokTersedia}'),
              contentPadding: EdgeInsets.zero,
            ),
          )
          .toList(),
    );
  }
}

class _ConsumableReviewStep extends StatelessWidget {
  const _ConsumableReviewStep({
    required this.selectedLab,
    required this.selectedDeskNo,
    required this.selectedItems,
    required this.consumableNotesController,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  final LabRoom? selectedLab;
  final String? selectedDeskNo;
  final List<BookingItemDraft> selectedItems;
  final TextEditingController consumableNotesController;
  final void Function(LabInventory inventory, int quantity) onQuantityChanged;
  final ValueChanged<LabInventory> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.electricBlue.withValues(alpha: 0.16),
                AppTheme.vibrantPurple.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.electricBlue.withValues(alpha: 0.18),
            ),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ReviewPill(
                icon: Icons.meeting_room_outlined,
                label: 'Ruangan',
                value: selectedLab?.name ?? 'Belum dipilih',
              ),
              _ReviewPill(
                icon: Icons.location_on_outlined,
                label: 'Lokasi',
                value: selectedLab?.location ?? '-',
              ),
              _ReviewPill(
                icon: Icons.desktop_windows_outlined,
                label: 'Meja',
                value: selectedDeskNo ?? 'Opsional',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: consumableNotesController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Catatan barang habis pakai / kebutuhan praktikum',
            hintText: 'Contoh: kabel jumper, kertas label, spidol board...',
            prefixIcon: Icon(Icons.note_alt_outlined),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Ringkasan Barang',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (selectedItems.isEmpty)
          const _EmptyBookingItems()
        else
          ...selectedItems.map(
            (draft) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectedItemTile(
                draft: draft,
                onQuantityChanged: onQuantityChanged,
                onRemoveItem: onRemoveItem,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Saat dikirim, data ruangan, meja, dan barang yang dipilih akan tersimpan ke tabel bookings dan booking_items Supabase.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.muted, height: 1.4),
        ),
      ],
    );
  }
}

class _ReviewPill extends StatelessWidget {
  const _ReviewPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.cyberGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedItemTile extends StatelessWidget {
  const _SelectedItemTile({
    required this.draft,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  final BookingItemDraft draft;
  final void Function(LabInventory inventory, int quantity) onQuantityChanged;
  final ValueChanged<LabInventory> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final inventory = draft.inventory;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.electricBlue.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.electricBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inventory.namaAlat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Stok tersedia ${inventory.stokTersedia}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kurangi jumlah',
            onPressed: draft.quantity <= 1
                ? null
                : () => onQuantityChanged(inventory, draft.quantity - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '${draft.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          IconButton(
            tooltip: 'Tambah jumlah',
            onPressed: draft.quantity >= inventory.stokTersedia
                ? null
                : () => onQuantityChanged(inventory, draft.quantity + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            tooltip: 'Hapus barang',
            onPressed: () => onRemoveItem(inventory),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _EmptyBookingItems extends StatelessWidget {
  const _EmptyBookingItems();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.electricBlue.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        'Belum ada barang dipilih. Pengajuan ruangan tetap bisa dikirim, atau kembali ke langkah sebelumnya untuk menambahkan alat.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted, height: 1.4),
      ),
    );
  }
}
