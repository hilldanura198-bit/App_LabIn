import 'package:flutter_test/flutter_test.dart';
import 'package:labin/features/dashboard/data/dashboard_models.dart';

void main() {
  group('resolveInventorySelection', () {
    test('returns the matching inventory from the current campus list by id', () {
      final previousSelection = const LabInventory(
        id: 'inventory-1',
        labId: 'lab-a',
        namaAlat: 'Laptop',
        totalStok: 4,
        stokTersedia: 4,
        kondisi: 'bagus',
        type: 'alat',
      );

      final currentInventories = <LabInventory>[
        const LabInventory(
          id: 'inventory-2',
          labId: 'lab-b',
          namaAlat: 'Proyektor',
          totalStok: 2,
          stokTersedia: 2,
          kondisi: 'bagus',
          type: 'alat',
        ),
        const LabInventory(
          id: 'inventory-1',
          labId: 'lab-a',
          namaAlat: 'Laptop',
          totalStok: 4,
          stokTersedia: 4,
          kondisi: 'bagus',
          type: 'alat',
        ),
      ];

      final resolved = resolveInventorySelection(
        currentInventories,
        previousSelection,
      );

      expect(resolved, isNotNull);
      expect(resolved!.id, 'inventory-1');
      expect(identical(resolved, currentInventories[1]), isTrue);
    });

    test('returns null when the previous selection is not present in the new list', () {
      final previousSelection = const LabInventory(
        id: 'inventory-1',
        labId: 'lab-a',
        namaAlat: 'Laptop',
        totalStok: 4,
        stokTersedia: 4,
        kondisi: 'bagus',
        type: 'alat',
      );

      final currentInventories = <LabInventory>[
        const LabInventory(
          id: 'inventory-2',
          labId: 'lab-b',
          namaAlat: 'Proyektor',
          totalStok: 2,
          stokTersedia: 2,
          kondisi: 'bagus',
          type: 'alat',
        ),
      ];

      expect(
        resolveInventorySelection(currentInventories, previousSelection),
        isNull,
      );
    });
  });
}
