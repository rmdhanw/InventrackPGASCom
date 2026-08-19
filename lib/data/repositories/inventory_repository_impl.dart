import 'package:inventrack/data/datasources/inventory_remote_data_source.dart';
import 'package:inventrack/domain/entities/inventory_entity.dart';
import 'package:inventrack/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  List<String>? _cachedCategories;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<String>> getCategories() async {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    _cachedCategories = await remoteDataSource.getCategories();
    return _cachedCategories!;
  }

  @override
  Future<void> addInventoryItem({
    required String nomorSerial,
    required String namaBarang,
    required String kategori,
    required String status,
    String? kondisi,
    String? keterangan,
  }) async {
    await remoteDataSource.addInventoryItem(
      nomorSerial: nomorSerial,
      namaBarang: namaBarang,
      kategori: kategori,
      status: status,
      kondisi: kondisi,
      keterangan: keterangan,
    );
    // Invalidate categories cache so next load refreshes if needed
    _cachedCategories = null;
  }

  @override
  Future<void> addMultipleInventoryItems({
    required List<Map<String, dynamic>> items,
  }) async {
    await remoteDataSource.addMultipleInventoryItems(items: items);
    _cachedCategories = null;
  }

  @override
  Future<InventoryEntity?> getItemBySerial(String nomorSerial) async {
    return await remoteDataSource.getItemBySerial(nomorSerial);
  }

  @override
  Future<InventoryEntity?> getItemBySerialForTransaction(String nomorSerial) async {
    return await remoteDataSource.getItemBySerialForTransaction(nomorSerial);
  }

  @override
  Future<void> addTransaction({
    required String nomorSerial,
    required String namaBarang,
    required String kategori,
    required String status,
    String? kondisi,
    String? keterangan,
  }) async {
    await remoteDataSource.addTransaction(
      nomorSerial: nomorSerial,
      namaBarang: namaBarang,
      kategori: kategori,
      status: status,
      kondisi: kondisi,
      keterangan: keterangan,
    );
  }

  @override
  Future<void> addMultipleTransactions({
    required List<Map<String, dynamic>> items,
  }) async {
    await remoteDataSource.addMultipleTransactions(items: items);
  }

  @override
  Future<void> deleteInventoryItem(String nomorSerial) async {
    await remoteDataSource.deleteInventoryItem(nomorSerial);
    _cachedCategories = null;
  }

  @override
  Future<void> editInventory({
    required String nomorSerial,
    required String namaBarang,
    required String kategori,
  }) async {
    await remoteDataSource.editInventory(
      nomorSerial: nomorSerial,
      namaBarang: namaBarang,
      kategori: kategori,
    );
    _cachedCategories = null;
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await remoteDataSource.deleteTransaction(transactionId);
  }

  @override
  Future<void> editTransaction({
    required String transactionId,
    required String status,
    String? kondisi,
    String? keterangan,
  }) async {
    await remoteDataSource.editTransaction(
      transactionId: transactionId,
      status: status,
      kondisi: kondisi,
      keterangan: keterangan,
    );
  }
}
