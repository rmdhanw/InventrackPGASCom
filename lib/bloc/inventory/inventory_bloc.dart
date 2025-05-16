import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/models/inventory.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final FirebaseFirestore _firestore;

  InventoryBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(InventoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddInventoryItem>(_onAddInventoryItem);
    on<LoadItemBySerial>(_onLoadItemBySerial);
    on<AddTransaction>(_onAddTransaction);
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
    on<InventoryEventEditInventory>(_onEditInventory);
    on<InventoryEventDeleteTransaction>(_onDeleteTransaction);
    on<InventoryEventEditTransaction>(_onEditTransaction);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final snapshot = await _firestore
          .collection("inventory")
          .doc("data")
          .collection("items")
          .get();

      final Set<String> uniqueCategories = {};
      for (var doc in snapshot.docs) {
        if (doc.data().containsKey('kategori')) {
          uniqueCategories.add(doc['kategori'] as String);
        }
      }

      final List<String> kategoriList = uniqueCategories.toList()..sort();

      emit(InventoryLoaded(categories: kategoriList));
    } catch (e) {
      emit(InventoryError('Gagal memuat kategori: $e'));
    }
  }

  Future<void> _onAddInventoryItem(
      AddInventoryItem event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final tanggalFormatted = DateFormat('dd-MM-yyyy').format(DateTime.now());

      final docRef = _firestore
          .collection('inventory')
          .doc('data')
          .collection('items')
          .doc(event.nomorSerial);

      await docRef.set({
        'kategori': event.kategori,
        'namaBarang': event.namaBarang,
        'nomorSerial': event.nomorSerial,
        'tanggal': tanggalFormatted,
        'timestamp': FieldValue.serverTimestamp(),
      });

      add(LoadCategories());

      emit(InventorySuccess('Item berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan barang: $e'));
    }
  }

  Future<void> _onEditInventory(
      InventoryEventEditInventory event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      if (event.nomorSerialOld != event.nomorSerial) {
        await _firestore
            .collection('inventory')
            .doc('data')
            .collection('items')
            .doc(event.nomorSerial)
            .set({
          'kategori': event.kategori,
          'namaBarang': event.namaBarang,
          'nomorSerial': event.nomorSerial,
          'tanggal': event.tanggal,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore
            .collection('inventory')
            .doc('data')
            .collection('items')
            .doc(event.nomorSerialOld)
            .delete();
      } else {
        await _firestore
            .collection('inventory')
            .doc('data')
            .collection('items')
            .doc(event.nomorSerial)
            .update({
          'kategori': event.kategori,
          'namaBarang': event.namaBarang,
          'nomorSerial': event.nomorSerial,
          'tanggal': event.tanggal,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      emit(InventoryStateCompleteEdit('Data berhasil diperbarui'));
    } catch (e) {
      emit(InventoryError('Gagal mengupdate data: $e'));
    }
  }

  Future<void> _onAddTransaction(
      AddTransaction event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());

    try {
      final now = DateTime.now();
      final formattedDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final docRef = await _firestore
          .collection('inventory')
          .doc('transaction')
          .collection('items')
          .add({
        'nomorSerial': event.nomorSerial,
        'kategori': event.kategori,
        'namaBarang': event.namaBarang,
        'status': event.status,
        'kondisi': event.kondisi,
        'keterangan': event.keterangan,
        'tanggal': formattedDate,
      });

      await docRef.update({"id": docRef.id});

      emit(InventorySuccess('Transaksi berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan transaksi: $e'));
    }
  }

  Future<void> _onDeleteInventoryItem(
      DeleteInventoryItem event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await _firestore
          .collection('inventory')
          .doc('data')
          .collection('items')
          .doc(event.nomorSerial)
          .delete();

      emit(InventorySuccess('Item berhasil dihapus'));
    } catch (e) {
      emit(InventoryError('Gagal menghapus item: $e'));
    }
  }

  Future<void> _onEditTransaction(
      InventoryEventEditTransaction event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await _firestore
          .collection('inventory')
          .doc('transaction')
          .collection('items')
          .doc(event.id)
          .update({
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
      await _firestore
          .collection('inventory')
          .doc('transaction')
          .collection('items')
          .doc(event.id)
          .delete();

      emit(InventorySuccess('Data transaksi berhasil dihapus'));
    } catch (e) {
      emit(InventoryError('Gagal menghapus transaksi: $e'));
    }
  }

  Future<void> _onLoadItemBySerial(
      LoadItemBySerial event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final doc = await _firestore
          .collection('inventory')
          .doc('data')
          .collection('items')
          .doc(event.serialNumber)
          .get();

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

  Stream<List<Inventory>> streamInventoryTransactions({
    required String startDate,
    required String endDate,
    String? status,
    String? category,
  }) async* {
    DateTime start = DateFormat('dd-MM-yyyy').parse(startDate);
    DateTime end = DateFormat('dd-MM-yyyy').parse(endDate);

    end = end.add(const Duration(days: 1));

    Query<Map<String, dynamic>> query = _firestore
        .collection("inventory")
        .doc("transaction")
        .collection("items")
        .where("tanggal", isGreaterThanOrEqualTo: startDate)
        .where("tanggal", isLessThanOrEqualTo: endDate)
        .orderBy("tanggal", descending: true);

    await for (QuerySnapshot<Map<String, dynamic>> snapshot
        in query.snapshots()) {
      try {
        List<Inventory> transactions = [];

        for (var doc in snapshot.docs) {
          final Map<String, dynamic> data = doc.data();
          final Inventory transaction = Inventory.fromJson(data);

          DateTime? docDate;
          try {
            if (transaction.tanggal != null) {
              docDate = DateFormat('dd-MM-yyyy').parse(transaction.tanggal!);
            }
          } catch (e) {
            debugPrint('Error parsing date: ${transaction.tanggal}');
          }

          if (docDate == null ||
              docDate.isBefore(start) ||
              docDate.isAfter(end)) {
            continue;
          }

          if (status != null &&
              status != 'Semua' &&
              transaction.status?.toLowerCase() != status.toLowerCase()) {
            continue;
          }

          if (category != null &&
              category != 'Semua' &&
              transaction.kategori?.toLowerCase() != category.toLowerCase()) {
            continue;
          }

          transactions.add(transaction);
        }

        yield transactions;
      } catch (e) {
        debugPrint('Error processing inventory transactions: $e');
        yield [];
      }
    }
  }

  String getTodayDateFormatted() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }
}
