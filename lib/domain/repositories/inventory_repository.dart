import 'package:inventrack/domain/entities/inventory_entity.dart';

abstract class InventoryRepository {
  Future<List<String>> getCategories();

  Future<void> addInventoryItem({
    required String nomorSerial,
    required String namaBarang,
    required String kategori,
    required String status,
    String? kondisi,
    String? keterangan,
  });

  Future<void> addMultipleInventoryItems({
    required List<Map<String, dynamic>> items,
  });

  Future<InventoryEntity?> getItemBySerial(String nomorSerial);

  Future<InventoryEntity?> getItemBySerialForTransaction(String nomorSerial);

  Future<void> addTransaction({
    required String nomorSerial,
    required String namaBarang,
    required String kategori,
    required String status,
    String? kondisi,
    String? keterangan,
  });

  Future<void> addMultipleTransactions({
    required List<Map<String, dynamic>> items,
  });

  Future<void> deleteInventoryItem(String nomorSerial);

  Future<void> editInventory({
    required String nomorSerial,
    required String namaBarang,
    required String kategori,
  });

  Future<void> deleteTransaction(String transactionId);

  Future<void> editTransaction({
    required String transactionId,
    required String status,
    String? kondisi,
    String? keterangan,
  });
}
