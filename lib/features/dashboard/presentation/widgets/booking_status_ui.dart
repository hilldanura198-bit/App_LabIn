import 'package:flutter/material.dart';

class BookingStatusUi {
  const BookingStatusUi._();

  static Color color(String status) {
    return switch (status) {
      'approved_aslab' || 'approved_kalab' => const Color(0xFF16A34A),
      'active' => const Color(0xFF0EA5E9),
      'returned' => const Color(0xFF64748B),
      'rejected' => const Color(0xFFDC2626),
      _ => const Color(0xFFFF9800),
    };
  }

  static IconData icon(String status) {
    return switch (status) {
      'approved_aslab' || 'approved_kalab' => Icons.verified_outlined,
      'active' => Icons.play_circle_outline_rounded,
      'returned' => Icons.assignment_turned_in_outlined,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.pending_actions_outlined,
    };
  }

  static String label(String status) {
    return switch (status) {
      'approved_aslab' || 'approved_kalab' => 'Disetujui',
      'active' => 'Sedang Dipakai',
      'returned' => 'Selesai',
      'rejected' => 'Ditolak',
      _ => 'Pending',
    };
  }

  static bool isApprovedOrActive(String status) {
    return status == 'approved_aslab' ||
        status == 'approved_kalab' ||
        status == 'active';
  }
}
