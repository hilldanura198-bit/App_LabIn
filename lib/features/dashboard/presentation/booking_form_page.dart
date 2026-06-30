import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/lab_catalog.dart';
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
  final _stepOneKey = GlobalKey<FormState>();
  final _stepTwoKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _programStudiController = TextEditingController();
  final _waController = TextEditingController();
  final _purposeController = TextEditingController();
  final _otherItemsController = TextEditingController();
  final _requestDateController = TextEditingController();
  final _borrowDateController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  int _step = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _borrowForSelf = true;
  ProfileSettings? _activeProfile;

  List<LabInventory> _inventories = const [];
  String? _selectedFacultyCode;
  String? _selectedLabId;
  DateTime? _requestDate;
  DateTime? _borrowDate;
  DateTime? _returnDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Map<String, BookingItemDraft> _selectedItems = {};

  String get _invalidMessage => 'Data belum sesuai!';

  bool get _hasSelectedItems =>
      _selectedItems.isNotEmpty || _otherItemsController.text.trim().isNotEmpty;

  bool get _isStepOneValid {
    return _nameController.text.trim().isNotEmpty &&
        AppValidation.isValidWhatsappNumber(_waController.text) &&
        _requestDate != null &&
        _borrowDate != null &&
        _returnDate != null &&
        _startTime != null &&
        _endTime != null &&
        _isReturnAfterStart() &&
        _purposeController.text.trim().length >= 8;
  }

  bool get _isStepTwoValid {
    return (_selectedFacultyCode ?? '').trim().isNotEmpty &&
        (_selectedLabId ?? '').trim().isNotEmpty;
  }

  bool get _canProceedCurrentStep {
    return switch (_step) {
      0 => _isStepOneValid,
      1 => _isStepTwoValid,
      2 => _hasSelectedItems,
      _ => _isStepOneValid && _isStepTwoValid,
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedFacultyCode = AppLabCatalog.faculties.first.code;
    _selectedLabId = AppLabCatalog.labsForFaculty(
      _selectedFacultyCode!,
    ).first.id;
    for (final controller in [
      _nameController,
      _nimController,
      _programStudiController,
      _waController,
      _purposeController,
      _otherItemsController,
      _requestDateController,
      _borrowDateController,
      _returnDateController,
      _startTimeController,
      _endTimeController,
    ]) {
      controller.addListener(_handleTextChange);
    }
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _nimController,
      _programStudiController,
      _waController,
      _purposeController,
      _otherItemsController,
      _requestDateController,
      _borrowDateController,
      _returnDateController,
      _startTimeController,
      _endTimeController,
    ]) {
      controller.removeListener(_handleTextChange);
    }
    _nameController.dispose();
    _nimController.dispose();
    _programStudiController.dispose();
    _waController.dispose();
    _purposeController.dispose();
    _otherItemsController.dispose();
    _requestDateController.dispose();
    _borrowDateController.dispose();
    _returnDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  List<LabCatalog> get _availableLabs {
    final code = _selectedFacultyCode ?? AppLabCatalog.faculties.first.code;
    final labs = AppLabCatalog.labsForFaculty(code);
    return labs.isEmpty ? AppLabCatalog.labs : labs;
  }

  LabCatalog? get _selectedLab {
    for (final lab in AppLabCatalog.labs) {
      if (lab.id == _selectedLabId) {
        return lab;
      }
    }
    return null;
  }

  List<LabInventory> get _selectedLabInventories {
    final labId = _selectedLabId;
    if (labId == null) return const [];
    return _inventories.where((item) => item.labId == labId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vibrantPurple.withValues(alpha: 0.12),
      appBar: const GlassAppBar(title: 'Formulir Peminjaman'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.vibrantPurple.withValues(alpha: 0.22),
              AppTheme.electricBlue.withValues(alpha: 0.10),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth >= 980
                        ? 920.0
                        : constraints.maxWidth;
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppTheme.electricBlue.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.vibrantPurple.withValues(
                                    alpha: 0.16,
                                  ),
                                  blurRadius: 32,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Detail Peminjaman',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lengkapi data reservasi, pilih laboratorium, lalu cek ulang sebelum dikirim.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme
                                        .copyWith(
                                          primary: AppTheme.electricBlue,
                                        ),
                                  ),
                                  child: Stepper(
                                    currentStep: _step,
                                    type: StepperType.vertical,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    margin: EdgeInsets.zero,
                                    onStepContinue: _submitting
                                        ? null
                                        : _handleStepContinue,
                                    onStepCancel: _submitting || _step == 0
                                        ? null
                                        : () => setState(() => _step--),
                                    controlsBuilder: (context, details) {
                                      final isLast = _step == 3;
                                      final canProceed =
                                          _canProceedCurrentStep &&
                                          !_submitting;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: CyberGradientButton(
                                                onPressed: canProceed
                                                    ? details.onStepContinue
                                                    : null,
                                                child: _submitting && isLast
                                                    ? const SizedBox.square(
                                                        dimension: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : Text(
                                                        isLast
                                                            ? 'send'.tr()
                                                            : 'continue'.tr(),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: _submitting
                                                    ? null
                                                    : (_step == 0
                                                          ? () => Navigator.of(
                                                              context,
                                                            ).maybePop()
                                                          : details
                                                                .onStepCancel),
                                                child: Text(
                                                  _step == 0
                                                      ? 'cancel'.tr()
                                                      : 'back'.tr(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    steps: [
                                      Step(
                                        title: Text('identity_schedule'.tr()),
                                        isActive: _step >= 0,
                                        content: Form(
                                          key: _stepOneKey,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          child: _StepShell(
                                            child: Wrap(
                                              spacing: 14,
                                              runSpacing: 14,
                                              children: [
                                                SizedBox(
                                                  width:
                                                      constraints.maxWidth >=
                                                          720
                                                      ? constraints.maxWidth
                                                      : double.infinity,
                                                  child: SegmentedButton<bool>(
                                                    segments: const [
                                                      ButtonSegment<bool>(
                                                        value: true,
                                                        icon: Icon(
                                                          Icons
                                                              .account_circle_outlined,
                                                        ),
                                                        label: Text(
                                                          'Atas Nama Diri Sendiri',
                                                        ),
                                                      ),
                                                      ButtonSegment<bool>(
                                                        value: false,
                                                        icon: Icon(
                                                          Icons
                                                              .supervisor_account_outlined,
                                                        ),
                                                        label: Text(
                                                          'Atas Nama Orang Lain',
                                                        ),
                                                      ),
                                                    ],
                                                    selected: {_borrowForSelf},
                                                    onSelectionChanged:
                                                        (selected) =>
                                                            _setBorrowerDelegation(
                                                              selected.first,
                                                            ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller: _nameController,
                                                    readOnly: _borrowForSelf,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Nama Peminjam',
                                                          prefixIcon: Icon(
                                                            Icons
                                                                .person_outline,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller: _nimController,
                                                    readOnly: true,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'NIM / NIP',
                                                          prefixIcon: Icon(
                                                            Icons
                                                                .badge_outlined,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller:
                                                        _programStudiController,
                                                    readOnly: true,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Program Studi',
                                                          prefixIcon: Icon(
                                                            Icons
                                                                .school_outlined,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller: _waController,
                                                    readOnly: _borrowForSelf,
                                                    keyboardType:
                                                        TextInputType.phone,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return _invalidMessage;
                                                      }
                                                      if (!AppValidation.isValidWhatsappNumber(
                                                        value,
                                                      )) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Nomor WhatsApp',
                                                          prefixIcon: Icon(
                                                            Icons
                                                                .phone_outlined,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller:
                                                        _requestDateController,
                                                    readOnly: true,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (_requestDate ==
                                                          null) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    onTap: () => _pickDate(
                                                      context: context,
                                                      title:
                                                          'Pilih Tanggal Pengajuan',
                                                      initial:
                                                          _requestDate ??
                                                          DateTime.now(),
                                                      onSelected: (date) {
                                                        setState(() {
                                                          _requestDate = date;
                                                          _requestDateController
                                                                  .text =
                                                              _formatDate(date);
                                                        });
                                                      },
                                                    ),
                                                    decoration: const InputDecoration(
                                                      labelText:
                                                          'Tanggal Pengajuan',
                                                      prefixIcon: Icon(
                                                        Icons
                                                            .event_note_outlined,
                                                      ),
                                                      suffixIcon: Icon(
                                                        Icons
                                                            .calendar_month_outlined,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller:
                                                        _borrowDateController,
                                                    readOnly: true,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (_borrowDate == null) {
                                                        return _invalidMessage;
                                                      }
                                                      if (_requestDate !=
                                                              null &&
                                                          _borrowDate!.isBefore(
                                                            _requestDate!,
                                                          )) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    onTap: () => _pickDate(
                                                      context: context,
                                                      title:
                                                          'Pilih Tanggal Peminjaman',
                                                      initial:
                                                          _borrowDate ??
                                                          DateTime.now().add(
                                                            const Duration(
                                                              days: 1,
                                                            ),
                                                          ),
                                                      onSelected: (date) {
                                                        setState(() {
                                                          _borrowDate = date;
                                                          if (_returnDate ==
                                                                  null ||
                                                              _returnDate!
                                                                  .isBefore(
                                                                    date,
                                                                  )) {
                                                            _returnDate = date;
                                                            _returnDateController
                                                                    .text =
                                                                _formatDate(
                                                                  date,
                                                                );
                                                          }
                                                          _borrowDateController
                                                                  .text =
                                                              _formatDate(date);
                                                        });
                                                      },
                                                    ),
                                                    decoration: const InputDecoration(
                                                      labelText:
                                                          'Tanggal Peminjaman',
                                                      prefixIcon: Icon(
                                                        Icons
                                                            .date_range_outlined,
                                                      ),
                                                      suffixIcon: Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller:
                                                        _returnDateController,
                                                    readOnly: true,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (_returnDate == null) {
                                                        return _invalidMessage;
                                                      }
                                                      if (_borrowDate != null &&
                                                          _returnDate!.isBefore(
                                                            _borrowDate!,
                                                          )) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    onTap: () => _pickDate(
                                                      context: context,
                                                      title:
                                                          'Pilih Tanggal Pengembalian',
                                                      initial:
                                                          _returnDate ??
                                                          _borrowDate ??
                                                          DateTime.now().add(
                                                            const Duration(
                                                              days: 1,
                                                            ),
                                                          ),
                                                      onSelected: (date) {
                                                        setState(() {
                                                          _returnDate = date;
                                                          _returnDateController
                                                                  .text =
                                                              _formatDate(date);
                                                        });
                                                      },
                                                    ),
                                                    decoration: const InputDecoration(
                                                      labelText:
                                                          'Tanggal Pengembalian',
                                                      prefixIcon: Icon(
                                                        Icons
                                                            .event_repeat_outlined,
                                                      ),
                                                      suffixIcon: Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller:
                                                        _startTimeController,
                                                    readOnly: true,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (_startTime == null) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    onTap: () => _pickTime(
                                                      context: context,
                                                      title: 'Pilih Jam Mulai',
                                                      initial:
                                                          _startTime ??
                                                          const TimeOfDay(
                                                            hour: 8,
                                                            minute: 0,
                                                          ),
                                                      onSelected: (time) {
                                                        setState(() {
                                                          _startTime = time;
                                                          _startTimeController
                                                                  .text =
                                                              _formatTime(time);
                                                        });
                                                      },
                                                    ),
                                                    decoration: const InputDecoration(
                                                      labelText: 'Jam Mulai',
                                                      prefixIcon: Icon(
                                                        Icons.schedule_outlined,
                                                      ),
                                                      suffixIcon: Icon(
                                                        Icons
                                                            .access_time_outlined,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: TextFormField(
                                                    controller:
                                                        _endTimeController,
                                                    readOnly: true,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (_endTime == null) {
                                                        return _invalidMessage;
                                                      }
                                                      if (_startTime != null &&
                                                          !_isReturnAfterStart()) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    onTap: () => _pickTime(
                                                      context: context,
                                                      title:
                                                          'Pilih Jam Selesai',
                                                      initial:
                                                          _endTime ??
                                                          const TimeOfDay(
                                                            hour: 11,
                                                            minute: 0,
                                                          ),
                                                      onSelected: (time) {
                                                        setState(() {
                                                          _endTime = time;
                                                          _endTimeController
                                                                  .text =
                                                              _formatTime(time);
                                                        });
                                                      },
                                                    ),
                                                    decoration: const InputDecoration(
                                                      labelText: 'Jam Selesai',
                                                      prefixIcon: Icon(
                                                        Icons.alarm_on_outlined,
                                                      ),
                                                      suffixIcon: Icon(
                                                        Icons
                                                            .access_time_filled_outlined,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width:
                                                      constraints.maxWidth >=
                                                          720
                                                      ? constraints.maxWidth
                                                      : double.infinity,
                                                  child: TextFormField(
                                                    controller:
                                                        _purposeController,
                                                    maxLines: 3,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return _invalidMessage;
                                                      }
                                                      if (value.trim().length <
                                                          8) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                    decoration: const InputDecoration(
                                                      labelText:
                                                          'Keperluan / Tujuan Peminjaman',
                                                      hintText:
                                                          'Contoh: praktikum, penelitian, seminar, atau tugas akhir',
                                                      prefixIcon: Icon(
                                                        Icons
                                                            .description_outlined,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Step(
                                        title: const Text(
                                          'Fakultas & Laboratorium',
                                        ),
                                        isActive: _step >= 1,
                                        content: Form(
                                          key: _stepTwoKey,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          child: _StepShell(
                                            child: Wrap(
                                              spacing: 14,
                                              runSpacing: 14,
                                              children: [
                                                _fieldBox(
                                                  context: context,
                                                  child: DropdownButtonFormField<String>(
                                                    initialValue:
                                                        _selectedFacultyCode,
                                                    isExpanded: true,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    items: AppLabCatalog
                                                        .faculties
                                                        .map(
                                                          (
                                                            faculty,
                                                          ) => DropdownMenuItem(
                                                            value: faculty.code,
                                                            child: Text(
                                                              '${faculty.code} - ${faculty.name}',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (value) {
                                                      if (value == null) return;
                                                      final labs =
                                                          AppLabCatalog.labsForFaculty(
                                                            value,
                                                          );
                                                      setState(() {
                                                        _selectedFacultyCode =
                                                            value;
                                                        _selectedLabId =
                                                            labs.isNotEmpty
                                                            ? labs.first.id
                                                            : AppLabCatalog
                                                                  .labs
                                                                  .first
                                                                  .id;
                                                      });
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Fakultas',
                                                          prefixIcon: Icon(
                                                            Icons
                                                                .account_balance_outlined,
                                                          ),
                                                        ),
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                _fieldBox(
                                                  context: context,
                                                  child: DropdownButtonFormField<String>(
                                                    initialValue:
                                                        _selectedLabId,
                                                    isExpanded: true,
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    items: _availableLabs
                                                        .map(
                                                          (
                                                            lab,
                                                          ) => DropdownMenuItem(
                                                            value: lab.id,
                                                            child: Text(
                                                              '${lab.name} · ${lab.location}',
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _selectedLabId = value;
                                                      });
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Laboratorium',
                                                          prefixIcon: Icon(
                                                            Icons
                                                                .science_outlined,
                                                          ),
                                                        ),
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return _invalidMessage;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                if (_selectedLab != null)
                                                  _LabPreviewCard(
                                                    lab: _selectedLab!,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Step(
                                        title: const Text(
                                          'Barang & Opsi Lainnya',
                                        ),
                                        isActive: _step >= 2,
                                        content: _StepShell(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              FormField<bool>(
                                                autovalidateMode:
                                                    AutovalidateMode
                                                        .onUserInteraction,
                                                initialValue: _hasSelectedItems,
                                                validator: (_) {
                                                  if (_hasSelectedItems) {
                                                    return null;
                                                  }
                                                  return _invalidMessage;
                                                },
                                                builder: (field) => Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    _InventoryChecklist(
                                                      inventories:
                                                          _selectedLabInventories,
                                                      selectedItems:
                                                          _selectedItems,
                                                      onToggle: _toggleItem,
                                                      onQuantityChanged:
                                                          _updateItemQuantity,
                                                      onRemoveItem: _removeItem,
                                                    ),
                                                    if (field.errorText !=
                                                        null) ...[
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        field.errorText!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: Colors
                                                                  .redAccent,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 14),
                                              TextFormField(
                                                controller:
                                                    _otherItemsController,
                                                minLines: 3,
                                                maxLines: 5,
                                                autovalidateMode:
                                                    AutovalidateMode
                                                        .onUserInteraction,
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                validator: (value) {
                                                  if (_selectedItems
                                                          .isNotEmpty ||
                                                      (value != null &&
                                                          value
                                                              .trim()
                                                              .isNotEmpty)) {
                                                    return null;
                                                  }
                                                  return _invalidMessage;
                                                },
                                                decoration: const InputDecoration(
                                                  labelText: 'Opsi Lainnya',
                                                  hintText:
                                                      'Tulis request alat tambahan atau kebutuhan khusus lainnya',
                                                  prefixIcon: Icon(
                                                    Icons
                                                        .pending_actions_outlined,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Step(
                                        title: const Text('Review & Kirim'),
                                        isActive: _step >= 3,
                                        content: _ReviewPanel(
                                          requestDate: _requestDate,
                                          borrowDate: _borrowDate,
                                          returnDate: _returnDate,
                                          startTime: _startTime,
                                          endTime: _endTime,
                                          selectedFacultyCode:
                                              _selectedFacultyCode,
                                          selectedLab: _selectedLab,
                                          borrowerName: _nameController.text
                                              .trim(),
                                          whatsappNumber: _waController.text
                                              .trim(),
                                          purpose: _purposeController.text
                                              .trim(),
                                          selectedItems: _selectedItems.values
                                              .toList(),
                                          otherItems: _otherItemsController.text
                                              .trim(),
                                          onEditData: () =>
                                              setState(() => _step = 0),
                                          onAddItem: () =>
                                              setState(() => _step = 2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        widget.repository.watchInventories().first,
        widget.repository.fetchProfileSettings(),
      ]);
      final inventories = results[0] as List<LabInventory>;
      final profile = results[1] as ProfileSettings;
      if (!mounted) return;
      _activeProfile = profile;
      _applyProfileAutofill();
      setState(() {
        _inventories = inventories;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _setBorrowerDelegation(bool forSelf) {
    setState(() {
      _borrowForSelf = forSelf;
      if (forSelf) {
        _applyProfileAutofill();
      } else {
        _nameController.clear();
        _nimController.clear();
        _programStudiController.clear();
        _waController.clear();
      }
    });
  }

  void _applyProfileAutofill() {
    final profile = _activeProfile;
    if (profile == null) return;
    _nameController.text = profile.name;
    _nimController.text = profile.nimNip;
    _programStudiController.text = profile.programStudi;
    _waController.text = profile.whatsappNumber;
  }

  Future<void> _handleStepContinue() async {
    if (_step == 0) {
      if (!(_stepOneKey.currentState?.validate() ?? false)) {
        _showWarning(_invalidMessage);
        return;
      }
      if (!_isReturnAfterStart()) {
        _showWarning(_invalidMessage);
        return;
      }
      if (_borrowDate != null &&
          _requestDate != null &&
          _borrowDate!.isBefore(_requestDate!)) {
        _showWarning(_invalidMessage);
        return;
      }
      if (_returnDate != null &&
          _borrowDate != null &&
          _returnDate!.isBefore(_borrowDate!)) {
        _showWarning(_invalidMessage);
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (!(_stepTwoKey.currentState?.validate() ?? false)) {
        _showWarning(_invalidMessage);
        return;
      }
      setState(() => _step = 2);
      return;
    }

    if (_step == 2) {
      setState(() => _step = 3);
      return;
    }

    await _submitBooking();
  }

  Future<void> _submitBooking() async {
    if (!(_stepOneKey.currentState?.validate() ?? false) ||
        !(_stepTwoKey.currentState?.validate() ?? false)) {
      _showWarning(_invalidMessage);
      setState(() => _step = 0);
      return;
    }
    if (_borrowDate == null ||
        _requestDate == null ||
        _startTime == null ||
        _returnDate == null ||
        _endTime == null ||
        !_isReturnAfterStart()) {
      _showWarning(_invalidMessage);
      setState(() => _step = 0);
      return;
    }

    final selectedLab = _selectedLab;
    if (selectedLab == null) {
      _showWarning(_invalidMessage);
      setState(() => _step = 1);
      return;
    }

    try {
      setState(() => _submitting = true);
      final booking = await widget.repository.createMultiStepBooking(
        borrowerName: _nameController.text.trim(),
        whatsappNumber: AppValidation.normalizeWhatsappNumber(
          _waController.text.trim(),
        ),
        facultyCode: _selectedFacultyCode ?? AppLabCatalog.faculties.first.code,
        labId: selectedLab.id,
        labNameSnapshot: selectedLab.name,
        requestDate: _requestDate!,
        borrowDate: _borrowDate!,
        returnDate: _returnDate!,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        purpose: _purposeController.text.trim(),
        deskNo: null,
        items: _selectedItems.values.toList(),
        otherItems: _otherItemsController.text.trim().isEmpty
            ? null
            : _otherItemsController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BookingSuccessPage(booking: booking)),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
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
    setState(() {
      _selectedItems.remove(inventory.id);
    });
  }

  Future<void> _pickDate({
    required BuildContext context,
    required String title,
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: title,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required String title,
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: title,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  bool _isReturnAfterStart() {
    final borrowDate = _borrowDate;
    final returnDate = _returnDate;
    final start = _startTime;
    final end = _endTime;
    if (borrowDate == null ||
        returnDate == null ||
        start == null ||
        end == null) {
      return false;
    }
    final startDateTime = DateTime(
      borrowDate.year,
      borrowDate.month,
      borrowDate.day,
      start.hour,
      start.minute,
    );
    final endDateTime = DateTime(
      returnDate.year,
      returnDate.month,
      returnDate.day,
      end.hour,
      end.minute,
    );
    return endDateTime.isAfter(startDateTime);
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange.shade700),
    );
  }

  Widget _fieldBox({required BuildContext context, required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth.isFinite && maxWidth >= 680) {
          final boxWidth = ((maxWidth - 14) / 2).clamp(280.0, 420.0);
          return SizedBox(width: boxWidth, child: child);
        }
        return SizedBox(width: double.infinity, child: child);
      },
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _LabPreviewCard extends StatelessWidget {
  const _LabPreviewCard({required this.lab});

  final LabCatalog lab;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.campusGradientOf(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lab.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${lab.facultyCode} • ${lab.location}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(lab.description, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _InventoryChecklist extends StatelessWidget {
  const _InventoryChecklist({
    required this.inventories,
    required this.selectedItems,
    required this.onToggle,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  final List<LabInventory> inventories;
  final Map<String, BookingItemDraft> selectedItems;
  final void Function(LabInventory inventory, bool selected) onToggle;
  final void Function(LabInventory inventory, int quantity) onQuantityChanged;
  final ValueChanged<LabInventory> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    if (inventories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.electricBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.14),
          ),
        ),
        child: const Text(
          'Belum ada inventaris yang tersedia untuk laboratorium ini.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: inventories
          .map(
            (inventory) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InventoryTile(
                inventory: inventory,
                selected: selectedItems.containsKey(inventory.id),
                draft: selectedItems[inventory.id],
                onToggle: onToggle,
                onQuantityChanged: onQuantityChanged,
                onRemoveItem: onRemoveItem,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.inventory,
    required this.selected,
    required this.draft,
    required this.onToggle,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  final LabInventory inventory;
  final bool selected;
  final BookingItemDraft? draft;
  final void Function(LabInventory inventory, bool selected) onToggle;
  final void Function(LabInventory inventory, int quantity) onQuantityChanged;
  final ValueChanged<LabInventory> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final isAvailable = inventory.isAvailable;
    final quantity = draft?.quantity ?? 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppTheme.electricBlue
              : AppTheme.electricBlue.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: isAvailable
                ? (value) => onToggle(inventory, value ?? false)
                : null,
            title: Text(
              inventory.namaAlat,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              isAvailable
                  ? 'Stok tersedia ${inventory.stokTersedia}'
                  : 'Stok habis',
            ),
            secondary: Icon(
              isAvailable ? Icons.inventory_2_outlined : Icons.block_outlined,
              color: isAvailable ? AppTheme.electricBlue : Colors.red,
            ),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: quantity <= 1
                        ? null
                        : () => onQuantityChanged(inventory, quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: quantity >= inventory.stokTersedia
                        ? null
                        : () => onQuantityChanged(inventory, quantity + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => onRemoveItem(inventory),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.requestDate,
    required this.borrowDate,
    required this.returnDate,
    required this.startTime,
    required this.endTime,
    required this.selectedFacultyCode,
    required this.selectedLab,
    required this.borrowerName,
    required this.whatsappNumber,
    required this.purpose,
    required this.selectedItems,
    required this.otherItems,
    required this.onEditData,
    required this.onAddItem,
  });

  final DateTime? requestDate;
  final DateTime? borrowDate;
  final DateTime? returnDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? selectedFacultyCode;
  final LabCatalog? selectedLab;
  final String borrowerName;
  final String whatsappNumber;
  final String purpose;
  final List<BookingItemDraft> selectedItems;
  final String otherItems;
  final VoidCallback onEditData;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final items = selectedItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.campusGradientOf(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReviewChip(
                icon: Icons.person_outline,
                label: 'Nama',
                value: borrowerName,
              ),
              _ReviewChip(
                icon: Icons.phone_outlined,
                label: 'WhatsApp',
                value: whatsappNumber,
              ),
              _ReviewChip(
                icon: Icons.account_balance_outlined,
                label: 'Fakultas',
                value: selectedFacultyCode ?? '-',
              ),
              _ReviewChip(
                icon: Icons.science_outlined,
                label: 'Lab',
                value: selectedLab?.name ?? '-',
              ),
              _ReviewChip(
                icon: Icons.event_note_outlined,
                label: 'Pengajuan',
                value: requestDate == null
                    ? '-'
                    : dateFormatter.format(requestDate!),
              ),
              _ReviewChip(
                icon: Icons.date_range_outlined,
                label: 'Peminjaman',
                value: borrowDate == null
                    ? '-'
                    : dateFormatter.format(borrowDate!),
              ),
              _ReviewChip(
                icon: Icons.event_repeat_outlined,
                label: 'Pengembalian',
                value: returnDate == null
                    ? '-'
                    : dateFormatter.format(returnDate!),
              ),
              _ReviewChip(
                icon: Icons.schedule_outlined,
                label: 'Waktu',
                value:
                    '${startTime == null ? '-' : _formatTime(startTime!)} - ${endTime == null ? '-' : _formatTime(endTime!)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tujuan Peminjaman',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          purpose.isEmpty ? '-' : purpose,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Daftar Barang / Alat',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('Belum ada barang yang dipilih.')
        else
          ...items.map(
            (draft) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SelectedItemRow(draft: draft),
            ),
          ),
        if (otherItems.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Opsi Lainnya',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(otherItems),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEditData,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah Data'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Tambah Barang'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.electricBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Pastikan semua data sudah benar. Saat tombol Kirim ditekan, booking akan tersimpan ke sistem dan siap diproses.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted, height: 1.4),
          ),
        ),
      ],
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({
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
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedItemRow extends StatelessWidget {
  const _SelectedItemRow({required this.draft});

  final BookingItemDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.electricBlue.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppTheme.electricBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              draft.inventory.namaAlat,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'x${draft.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
