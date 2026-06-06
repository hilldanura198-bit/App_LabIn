import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

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
  final _selectedItems = <String, BookingItemDraft>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _waController.dispose();
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
      appBar: AppBar(title: const Text('Formulir Peminjaman')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stepper(
                currentStep: _step,
                onStepContinue: _continue,
                onStepCancel: _step == 0 ? null : () => setState(() => _step--),
                controlsBuilder: (context, details) {
                  final last = _step == 3;
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: details.onStepContinue,
                            child: Text(last ? 'Kirim Pengajuan' : 'Lanjut'),
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
                    content: DropdownButtonFormField<String>(
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
                    title: const Text('Barang Habis Pakai'),
                    isActive: _step >= 3,
                    content: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Barang habis pakai dicatat sebagai catatan praktikum. Pengajuan utama tetap tersimpan ke bookings dan booking_items.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
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

  Future<void> _continue() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    if (_selectedLabId == null) {
      return;
    }
    try {
      await widget.repository.createMultiStepBooking(
        labId: _selectedLabId!,
        noWhatsapp: _waController.text,
        tanggalPinjam: DateTime.now().add(const Duration(days: 1)),
        items: _selectedItems.values.toList(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan multi-step berhasil dikirim.')),
      );
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
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
