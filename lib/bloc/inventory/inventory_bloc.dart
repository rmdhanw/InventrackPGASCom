import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/models/inventory.dart';
import 'package:inventrack/screens/inventory/inventory_form.dart';
import 'package:inventrack/screens/inventory/inventory_transactionform.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final FirebaseFirestore _firestore;

  List<String>? _cachedCategories;

  static const String _inventoryDataPath = 'inventory/data/items';
  static const String _inventoryTransactionPath = 'inventory/transaction/items';

  static final DateFormat _dateFormatter = DateFormat('dd-MM-yyyy');

  InventoryBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(InventoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddInventoryItem>(_onAddInventoryItem);
    on<AddMultipleInventoryItems>(_onAddMultipleInventoryItems);
    on<LoadItemBySerial>(_onLoadItemBySerial);
    on<LoadItemBySerialForTransaction>(
        _onLoadItemBySerialForTransaction); // New handler
    on<AddTransaction>(_onAddTransaction);
    on<AddMultipleTransactions>(
        _onAddMultipleTransactions); // New handler for multiple transactions
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
    on<InventoryEventEditInventory>(_onEditInventory);
    on<InventoryEventDeleteTransaction>(_onDeleteTransaction);
    on<InventoryEventEditTransaction>(_onEditTransaction);
  }

  String get _todayFormatted => _dateFormatter.format(DateTime.now());

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection(_inventoryDataPath);

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection(_inventoryTransactionPath);

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<InventoryState> emit) async {
    if (_cachedCategories != null) {
      emit(CategoriesLoaded(categories: _cachedCategories!));
      return;
    }

    emit(InventoryLoading());
    try {
      final snapshot = await _itemsCollection.get();

      final Set<String> uniqueCategories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('kategori') && data['kategori'] != null) {
          uniqueCategories.add(data['kategori'] as String);
        }
      }

      _cachedCategories = uniqueCategories.toList()..sort();
      emit(CategoriesLoaded(categories: _cachedCategories!));
    } catch (e) {
      emit(InventoryError('Gagal memuat kategori: $e'));
    }
  }

  Future<void> _onAddInventoryItem(
      AddInventoryItem event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());

    // Gunakan batch write untuk operasi atomik
    final batch = _firestore.batch();

    try {
      // Tambah item ke koleksi data
      final itemRef = _itemsCollection.doc(event.nomorSerial);
      batch.set(itemRef, {
        'kategori': event.kategori,
        'namaBarang': event.namaBarang,
        'nomorSerial': event.nomorSerial,
        'tanggal': _todayFormatted,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Tambah transaksi
      final transactionRef = _transactionsCollection.doc();
      batch.set(transactionRef, {
        'id': transactionRef.id,
        'nomorSerial': event.nomorSerial,
        'kategori': event.kategori,
        'namaBarang': event.namaBarang,
        'status': event.status,
        'kondisi': event.kondisi,
        'keterangan': event.keterangan,
        'tanggal': _todayFormatted,
      });

      await batch.commit();

      // Update cache kategori jika kategori baru
      if (_cachedCategories != null &&
          !_cachedCategories!.contains(event.kategori)) {
        _cachedCategories!.add(event.kategori);
        _cachedCategories!.sort();
      }

      emit(InventorySuccess('Item berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan barang: $e'));
    }
  }

  // New method to handle multiple items
  Future<void> _onAddMultipleInventoryItems(
      AddMultipleInventoryItems event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());

    try {
      // Validasi duplikasi nomor serial dalam batch
      final serialNumbers = event.items
          .map((item) => item.nomorSerialController.text.trim())
          .toList();
      final duplicateSerials = <String>[];

      for (int i = 0; i < serialNumbers.length; i++) {
        for (int j = i + 1; j < serialNumbers.length; j++) {
          if (serialNumbers[i] == serialNumbers[j]) {
            duplicateSerials.add(serialNumbers[i]);
          }
        }
      }

      if (duplicateSerials.isNotEmpty) {
        emit(InventoryError(
            'Nomor serial duplikat ditemukan: ${duplicateSerials.join(', ')}'));
        return;
      }

      // Cek nomor serial yang sudah ada di database
      final existingSerials = <String>[];
      for (final serialNumber in serialNumbers) {
        final doc = await _itemsCollection.doc(serialNumber).get();
        if (doc.exists) {
          existingSerials.add(serialNumber);
        }
      }

      if (existingSerials.isNotEmpty) {
        emit(InventoryError(
            'Nomor serial sudah ada: ${existingSerials.join(', ')}'));
        return;
      }

      // Process semua items dalam batch
      final batch = _firestore.batch();
      final newCategories = <String>{};

      for (final item in event.items) {
        final nomorSerial = item.nomorSerialController.text.trim();
        final namaBarang = item.namaBarangController.text.trim();
        final kategori = item.getKategori();
        final status = item.selectedStatusBarang!;
        final kondisi = item.selectedKondisiBarang!;
        final keterangan = item.keteranganController.text.trim();

        final itemRef = _itemsCollection.doc(nomorSerial);
        batch.set(itemRef, {
          'kategori': kategori,
          'namaBarang': namaBarang,
          'nomorSerial': nomorSerial,
          'tanggal': _todayFormatted,
          'timestamp': FieldValue.serverTimestamp(),
        });

        final transactionRef = _transactionsCollection.doc();
        batch.set(transactionRef, {
          'id': transactionRef.id,
          'nomorSerial': nomorSerial,
          'kategori': kategori,
          'namaBarang': namaBarang,
          'status': status,
          'kondisi': kondisi,
          'keterangan': keterangan,
          'tanggal': _todayFormatted,
        });

        if (_cachedCategories != null &&
            !_cachedCategories!.contains(kategori)) {
          newCategories.add(kategori);
        }
      }

      await batch.commit();

      if (newCategories.isNotEmpty) {
        _cachedCategories?.addAll(newCategories);
        _cachedCategories?.sort();
      }

      final itemCount = event.items.length;
      emit(InventorySuccess('$itemCount item berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan items: $e'));
    }
  }

  // New handler untuk load item berdasarkan serial number untuk transaction form
  Future<void> _onLoadItemBySerialForTransaction(
      LoadItemBySerialForTransaction event,
      Emitter<InventoryState> emit) async {
    try {
      final doc = await _itemsCollection.doc(event.serialNumber).get();

      if (doc.exists) {
        final data = doc.data()!;
        emit(ItemLoadedForTransaction(
          namaBarang: data['namaBarang'] ?? '',
          kategori: data['kategori'] ?? '',
          index: event.index,
        ));
      } else {
        emit(InventoryError(
            'Data dengan nomor serial ${event.serialNumber} tidak ditemukan.'));
      }
    } catch (e) {
      emit(InventoryError('Gagal memuat data: $e'));
    }
  }

  // New handler untuk menambahkan multiple transactions
  Future<void> _onAddMultipleTransactions(
      AddMultipleTransactions event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());

    try {
      // Validasi bahwa semua nomor serial ada di database
      final missingSerials = <String>[];

      for (final transaction in event.transactions) {
        final nomorSerial = transaction.nomorSerialController.text.trim();
        final doc = await _itemsCollection.doc(nomorSerial).get();
        if (!doc.exists) {
          missingSerials.add(nomorSerial);
        }
      }

      if (missingSerials.isNotEmpty) {
        emit(InventoryError(
            'Nomor serial tidak ditemukan di inventory: ${missingSerials.join(', ')}'));
        return;
      }

      // Process semua transactions dalam batch
      final batch = _firestore.batch();

      for (final transaction in event.transactions) {
        final nomorSerial = transaction.nomorSerialController.text.trim();
        final namaBarang = transaction.namaBarangController.text.trim();
        final kategori = transaction.selectedKategori!;
        final status = transaction.selectedStatus!;
        final kondisi = transaction.selectedKondisi!;
        final keterangan = transaction.keteranganController.text.trim();

        final transactionRef = _transactionsCollection.doc();
        batch.set(transactionRef, {
          'id': transactionRef.id,
          'nomorSerial': nomorSerial,
          'kategori': kategori,
          'namaBarang': namaBarang,
          'status': status,
          'kondisi': kondisi,
          'keterangan': keterangan.isEmpty ? '-' : keterangan,
          'tanggal': _todayFormatted,
        });
      }

      await batch.commit();

      final transactionCount = event.transactions.length;
      emit(
          InventorySuccess('$transactionCount transaksi berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan transaksi: $e'));
    }
  }

  Future<void> _onEditInventory(
      InventoryEventEditInventory event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());

    final batch = _firestore.batch();

    try {
      if (event.nomorSerialOld != event.nomorSerial) {
        // Hapus dokumen lama dan buat dokumen baru
        final oldRef = _itemsCollection.doc(event.nomorSerialOld);
        final newRef = _itemsCollection.doc(event.nomorSerial);

        batch.delete(oldRef);
        batch.set(newRef, {
          'kategori': event.kategori,
          'namaBarang': event.namaBarang,
          'nomorSerial': event.nomorSerial,
          'tanggal': event.tanggal,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Update dokumen existing
        final ref = _itemsCollection.doc(event.nomorSerial);
        batch.update(ref, {
          'kategori': event.kategori,
          'namaBarang': event.namaBarang,
          'tanggal': event.tanggal,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Update cache kategori jika perlu
      _updateCategoryCache(event.kategori);

      emit(InventoryStateCompleteEdit('Data berhasil diperbarui'));
    } catch (e) {
      emit(InventoryError('Gagal mengupdate data: $e'));
    }
  }

  Future<void> _onAddTransaction(
      AddTransaction event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());

    try {
      final docRef = _transactionsCollection.doc();

      await docRef.set({
        'id': docRef.id,
        'nomorSerial': event.nomorSerial,
        'kategori': event.kategori,
        'namaBarang': event.namaBarang,
        'status': event.status,
        'kondisi': event.kondisi,
        'keterangan': event.keterangan,
        'tanggal': _todayFormatted,
      });

      emit(InventorySuccess('Transaksi berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan transaksi: $e'));
    }
  }

  Future<void> _onDeleteInventoryItem(
      DeleteInventoryItem event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await _itemsCollection.doc(event.nomorSerial).delete();
      emit(InventorySuccess('Item berhasil dihapus'));
    } catch (e) {
      emit(InventoryError('Gagal menghapus item: $e'));
    }
  }

  Future<void> _onEditTransaction(
      InventoryEventEditTransaction event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await _transactionsCollection.doc(event.id).update({
        'nomorSerial': event.nomorSerial,
        'kategori': event.kategori,
        'namaBarang': event.namaBarang,
        'status': event.status,
        'kondisi': event.kondisi,
        'keterangan': event.keterangan,
        'tanggal': event.tanggal,
      });

      emit(InventoryStateCompleteEdit('Data transaksi berhasil diperbarui'));
    } catch (e) {
      emit(InventoryError('Gagal mengupdate transaksi: $e'));
    }
  }

  Future<void> _onDeleteTransaction(InventoryEventDeleteTransaction event,
      Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await _transactionsCollection.doc(event.id).delete();
      emit(InventorySuccess('Data transaksi berhasil dihapus'));
    } catch (e) {
      emit(InventoryError('Gagal menghapus transaksi: $e'));
    }
  }

  Future<void> _onLoadItemBySerial(
      LoadItemBySerial event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final doc = await _itemsCollection.doc(event.serialNumber).get();

      if (doc.exists) {
        final data = doc.data()!;
        emit(ItemLoaded(
          namaBarang: data['namaBarang'] ?? '',
          kategori: data['kategori'] ?? '',
        ));
      } else {
        emit(InventoryError('Data tidak ditemukan.'));
      }
    } catch (e) {
      emit(InventoryError('Gagal memuat data: $e'));
    }
  }

  // Stream dengan filter yang sesuai dengan view
  Stream<List<Inventory>> streamInventoryTransactions({
    required String startDate,
    required String endDate,
    String? status,
    String? category,
  }) async* {
    try {
      final start = _dateFormatter.parse(startDate);
      final end = _dateFormatter.parse(endDate);

      // Gunakan query dasar tanpa filter kompleks untuk menghindari composite index
      Query<Map<String, dynamic>> query = _transactionsCollection
          .where("tanggal", isGreaterThanOrEqualTo: startDate)
          .where("tanggal", isLessThanOrEqualTo: endDate)
          .orderBy("tanggal", descending: true);

      await for (final snapshot in query.snapshots()) {
        final transactions = <Inventory>[];

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            final transaction = Inventory.fromJson(data);

            // Validasi tanggal
            DateTime? docDate;
            try {
              if (transaction.tanggal != null) {
                docDate = _dateFormatter.parse(transaction.tanggal!);
              }
            } catch (e) {
              debugPrint('Error parsing date: ${transaction.tanggal}');
            }

            if (docDate == null ||
                docDate.isBefore(start) ||
                docDate.isAfter(end.add(const Duration(days: 1)))) {
              continue;
            }

            // Filter status - sesuaikan dengan logika di view
            if (status != null && status != 'Semua Status') {
              if (transaction.status?.toLowerCase() != status.toLowerCase()) {
                continue;
              }
            }

            // Filter category - sesuaikan dengan logika di view
            if (category != null && category != 'Semua Kategori') {
              if (transaction.kategori?.toLowerCase() !=
                  category.toLowerCase()) {
                continue;
              }
            }

            transactions.add(transaction);
          } catch (e) {
            debugPrint('Error parsing transaction: ${doc.id} - $e');
          }
        }

        yield transactions;
      }
    } catch (e) {
      debugPrint('Error in streamInventoryTransactions: $e');
      yield [];
    }
  }

  // Helper method untuk update cache kategori
  void _updateCategoryCache(String newCategory) {
    if (_cachedCategories != null &&
        !_cachedCategories!.contains(newCategory)) {
      _cachedCategories!.add(newCategory);
      _cachedCategories!.sort();
    }
  }

  // Method untuk clear cache (misalnya saat logout)
  void clearCache() {
    _cachedCategories = null;
  }

  String getTodayDateFormatted() => _todayFormatted;
}
