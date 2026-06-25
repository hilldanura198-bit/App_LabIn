import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted({
    required this.inventoryStream,
    required this.bookingStream,
    this.campusName = 'Kampus Rektorat',
  });

  final bool inventoryStream;
  final bool bookingStream;
  final String campusName;
}

class DashboardCampusSelected extends DashboardEvent {
  const DashboardCampusSelected(this.campusName);

  final String campusName;
}

class DashboardDateSelected extends DashboardEvent {
  const DashboardDateSelected(this.date);

  final DateTime date;
}

class DashboardCartItemAdded extends DashboardEvent {
  const DashboardCartItemAdded(this.inventory);

  final LabInventory inventory;
}

class DashboardCartItemRemoved extends DashboardEvent {
  const DashboardCartItemRemoved(this.inventoryId);

  final String inventoryId;
}

class DashboardCheckoutRequested extends DashboardEvent {
  const DashboardCheckoutRequested({
    required this.startDateTime,
    required this.endDateTime,
  });

  final DateTime startDateTime;
  final DateTime endDateTime;
}

class DashboardMaintenanceReportSubmitted extends DashboardEvent {
  const DashboardMaintenanceReportSubmitted({
    required this.inventory,
    required this.description,
    required this.photo,
  });

  final LabInventory inventory;
  final String description;
  final XFile photo;
}

class DashboardAslabApprovalRequested extends DashboardEvent {
  const DashboardAslabApprovalRequested(this.bookingId);

  final String bookingId;
}

class DashboardQrValidationRequested extends DashboardEvent {
  const DashboardQrValidationRequested(this.rawCode);

  final String rawCode;
}

class DashboardKalabApprovalRequested extends DashboardEvent {
  const DashboardKalabApprovalRequested({
    required this.bookingId,
    required this.signatureBytes,
  });

  final String bookingId;
  final Uint8List signatureBytes;
}

class DashboardAuditScanRequested extends DashboardEvent {
  const DashboardAuditScanRequested(this.barcode);

  final String barcode;
}

class _InventoriesChanged extends DashboardEvent {
  const _InventoriesChanged(this.inventories);

  final List<LabInventory> inventories;
}

class _BookingsChanged extends DashboardEvent {
  const _BookingsChanged(this.bookings);

  final List<LabBooking> bookings;
}

class _DashboardFailed extends DashboardEvent {
  const _DashboardFailed(this.message);

  final String message;
}

class DashboardState {
  const DashboardState({
    required this.inventories,
    required this.bookings,
    required this.cart,
    required this.selectedDate,
    required this.busyHours,
    required this.isLoading,
    this.message,
    this.selectedCampus = 'Kampus Rektorat',
  });

  factory DashboardState.initial() {
    final now = DateTime.now();
    return DashboardState(
      inventories: const [],
      bookings: const [],
      cart: const {},
      selectedDate: DateTime(now.year, now.month, now.day, 9),
      busyHours: const [],
      isLoading: true,
      selectedCampus: 'Kampus Rektorat',
    );
  }

  final List<LabInventory> inventories;
  final List<LabBooking> bookings;
  final Map<String, BookingItemDraft> cart;
  final DateTime selectedDate;
  final List<BusyHour> busyHours;
  final bool isLoading;
  final String? message;
  final String selectedCampus;

  LabBooking? get latestBooking => bookings.isEmpty ? null : bookings.first;
  LabBooking? get activeHomeBooking {
    final activeStatuses = {
      'pending',
      'approved_aslab',
      'approved_kalab',
      'active',
      'late',
    };
    final activeBookings =
        bookings
            .where((booking) => activeStatuses.contains(booking.status))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activeBookings.isEmpty ? null : activeBookings.first;
  }

  int get cartCount => cart.values.fold(0, (sum, item) => sum + item.quantity);
  List<LabInventory> get criticalInventories =>
      inventories.where((inventory) => inventory.isCritical).toList();
  List<LabInventory> get lowStockInventories =>
      inventories.where((inventory) => inventory.stokTersedia < 3).toList();

  DashboardState copyWith({
    List<LabInventory>? inventories,
    List<LabBooking>? bookings,
    Map<String, BookingItemDraft>? cart,
    DateTime? selectedDate,
    List<BusyHour>? busyHours,
    bool? isLoading,
    String? message,
    String? selectedCampus,
    bool clearMessage = false,
  }) {
    return DashboardState(
      inventories: inventories ?? this.inventories,
      bookings: bookings ?? this.bookings,
      cart: cart ?? this.cart,
      selectedDate: selectedDate ?? this.selectedDate,
      busyHours: busyHours ?? this.busyHours,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
      selectedCampus: selectedCampus ?? this.selectedCampus,
    );
  }
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(DashboardState.initial()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardCampusSelected>(_onCampusSelected);
    on<_InventoriesChanged>(_onInventoriesChanged);
    on<_BookingsChanged>(_onBookingsChanged);
    on<_DashboardFailed>(_onFailed);
    on<DashboardDateSelected>(_onDateSelected);
    on<DashboardCartItemAdded>(_onCartItemAdded);
    on<DashboardCartItemRemoved>(_onCartItemRemoved);
    on<DashboardCheckoutRequested>(_onCheckoutRequested);
    on<DashboardMaintenanceReportSubmitted>(_onMaintenanceReportSubmitted);
    on<DashboardAslabApprovalRequested>(_onAslabApprovalRequested);
    on<DashboardQrValidationRequested>(_onQrValidationRequested);
    on<DashboardKalabApprovalRequested>(_onKalabApprovalRequested);
    on<DashboardAuditScanRequested>(_onAuditScanRequested);
  }

  final DashboardRepository _repository;
  StreamSubscription<List<LabInventory>>? _inventorySubscription;
  StreamSubscription<List<LabBooking>>? _bookingSubscription;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      if (event.inventoryStream) {
        await _inventorySubscription?.cancel();
        _inventorySubscription = _repository
            .watchInventoriesByCampus(event.campusName)
            .listen(
              (inventories) => add(_InventoriesChanged(inventories)),
              onError: (Object error) => add(_DashboardFailed(_message(error))),
            );
      }
      if (event.bookingStream) {
        await _bookingSubscription?.cancel();
        _bookingSubscription = _repository
            .watchBookingsByStatus([
              'pending',
              'approved_aslab',
              'approved_kalab',
              'active',
              'returned',
              'late',
            ])
            .listen(
              (bookings) => add(_BookingsChanged(bookings)),
              onError: (Object error) => add(_DashboardFailed(_message(error))),
            );
      } else {
        await _bookingSubscription?.cancel();
        _bookingSubscription = _repository.watchCurrentUserBookings().listen(
          (bookings) => add(_BookingsChanged(bookings)),
          onError: (Object error) => add(_DashboardFailed(_message(error))),
        );
      }
      final busyHours = await _repository.fetchBusyHours();
      emit(
        state.copyWith(
          busyHours: busyHours,
          isLoading: false,
          selectedCampus: event.campusName,
        ),
      );
    } on Object catch (error) {
      emit(state.copyWith(isLoading: false, message: _message(error)));
    }
  }

  Future<void> _onCampusSelected(
    DashboardCampusSelected event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCampus: event.campusName,
        isLoading: true,
        clearMessage: true,
      ),
    );
    await _inventorySubscription?.cancel();
    _inventorySubscription = _repository
        .watchInventoriesByCampus(event.campusName)
        .listen(
          (inventories) => add(_InventoriesChanged(inventories)),
          onError: (Object error) => add(_DashboardFailed(_message(error))),
        );
  }

  void _onInventoriesChanged(
    _InventoriesChanged event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(inventories: event.inventories, isLoading: false));
  }

  void _onBookingsChanged(
    _BookingsChanged event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(bookings: event.bookings, isLoading: false));
  }

  void _onFailed(_DashboardFailed event, Emitter<DashboardState> emit) {
    emit(state.copyWith(isLoading: false, message: event.message));
  }

  void _onDateSelected(
    DashboardDateSelected event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(selectedDate: event.date, clearMessage: true));
  }

  void _onCartItemAdded(
    DashboardCartItemAdded event,
    Emitter<DashboardState> emit,
  ) {
    final current = state.cart[event.inventory.id];
    final nextQuantity = (current?.quantity ?? 0) + 1;
    if (nextQuantity > event.inventory.stokTersedia) {
      emit(
        state.copyWith(
          message: 'Stok ${event.inventory.namaAlat} tidak cukup.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        cart: {
          ...state.cart,
          event.inventory.id: BookingItemDraft(
            inventory: event.inventory,
            quantity: nextQuantity,
          ),
        },
        clearMessage: true,
      ),
    );
  }

  void _onCartItemRemoved(
    DashboardCartItemRemoved event,
    Emitter<DashboardState> emit,
  ) {
    final nextCart = Map<String, BookingItemDraft>.from(state.cart);
    final current = nextCart[event.inventoryId];
    if (current == null) {
      return;
    }
    if (current.quantity <= 1) {
      nextCart.remove(event.inventoryId);
    } else {
      nextCart[event.inventoryId] = BookingItemDraft(
        inventory: current.inventory,
        quantity: current.quantity - 1,
      );
    }
    emit(state.copyWith(cart: nextCart, clearMessage: true));
  }

  Future<void> _onCheckoutRequested(
    DashboardCheckoutRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      final booking = await _repository.createBooking(
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        items: state.cart.values.toList(),
      );
      emit(
        state.copyWith(
          bookings: [
            booking,
            ...state.bookings.where((item) => item.id != booking.id),
          ],
          cart: const {},
          isLoading: false,
          message: 'checkout_success',
        ),
      );
    } on Object catch (error) {
      emit(state.copyWith(isLoading: false, message: _message(error)));
    }
  }

  Future<void> _onMaintenanceReportSubmitted(
    DashboardMaintenanceReportSubmitted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      await _repository.reportMaintenance(
        inventory: event.inventory,
        description: event.description,
        photo: event.photo,
      );
      emit(
        state.copyWith(
          isLoading: false,
          message: 'Laporan kerusakan terkirim.',
        ),
      );
    } on Object catch (error) {
      emit(state.copyWith(isLoading: false, message: _message(error)));
    }
  }

  Future<void> _onAslabApprovalRequested(
    DashboardAslabApprovalRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _repository.approveAslab(event.bookingId);
      emit(state.copyWith(message: 'Pengajuan diverifikasi Aslab.'));
    } on Object catch (error) {
      emit(state.copyWith(message: _message(error)));
    }
  }

  Future<void> _onQrValidationRequested(
    DashboardQrValidationRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _repository.applyQrValidation(event.rawCode);
      emit(state.copyWith(message: 'QR berhasil divalidasi.'));
    } on Object catch (error) {
      emit(state.copyWith(message: _message(error)));
    }
  }

  Future<void> _onKalabApprovalRequested(
    DashboardKalabApprovalRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _repository.approveKalab(
        bookingId: event.bookingId,
        signatureBytes: event.signatureBytes,
      );
      emit(state.copyWith(message: 'Persetujuan Kalab tersimpan.'));
    } on Object catch (error) {
      emit(state.copyWith(message: _message(error)));
    }
  }

  Future<void> _onAuditScanRequested(
    DashboardAuditScanRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      final nextStatus = await _repository.confirmItemHandover(event.barcode);
      emit(
        state.copyWith(
          isLoading: false,
          message: nextStatus == 'returned'
              ? 'Pengembalian barang berhasil dikonfirmasi.'
              : 'Serah terima barang berhasil dikonfirmasi.',
        ),
      );
    } on Object catch (error) {
      emit(state.copyWith(isLoading: false, message: _message(error)));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Future<void> close() async {
    await _inventorySubscription?.cancel();
    await _bookingSubscription?.cancel();
    return super.close();
  }
}
