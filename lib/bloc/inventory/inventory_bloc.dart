import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/domain/repositories/inventory_repository.dart';
import 'package:inventrack/models/inventory.dart';
import 'package:inventrack/screens/inventory/inventory_form.dart';
import 'package:inventrack/screens/inventory/inventory_transactionform.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository inventoryRepository;
  static final DateFormat _dateFormatter = DateFormat('dd-MM-yyyy');

  InventoryBloc({required this.inventoryRepository})
      : super(InventoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddInventoryItem>(_onAddInventoryItem);
    on<AddMultipleInventoryItems>(_onAddMultipleInventoryItems);
    on<LoadItemBySerial>(_onLoadItemBySerial);
    on<LoadItemBySerialForTransaction>(_onLoadItemBySerialForTransaction);
    on<AddTransaction>(_onAddTransaction);
    on<AddMultipleTransactions>(_onAddMultipleTransactions);
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
    on<InventoryEventEditInventory>(_onEditInventory);
    on<InventoryEventDeleteTransaction>(_onDeleteTransaction);
    on<InventoryEventEditTransaction>(_onEditTransaction);
  }

  String get _todayFormatted => _dateFormatter.format(DateTime.now());

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final categories = await inventoryRepository.getCategories();
      emit(CategoriesLoaded(categories: categories));
    } catch (e) {
      emit(InventoryError('Gagal memuat kategori: $e'));
    }
  }

  Future<void> _onAddInventoryItem(
      AddInventoryItem event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await inventoryRepository.addInventoryItem(
        nomorSerial: event.nomorSerial,
        namaBarang: event.namaBarang,
        kategori: event.kategori,
        status: event.status,
        kondisi: event.kondisi,
        keterangan: event.keterangan,
      );
      emit(InventorySuccess('Item berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan barang: $e'));
    }
  }

  Future<void> _onAddMultipleInventoryItems(
      AddMultipleInventoryItems event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final items = event.items.map((item) {
        return {
          'nomorSerial': item.nomorSerialController.text.trim(),
          'namaBarang': item.namaBarangController.text.trim(),
          'kategori': item.getKategori(),
          'status': item.selectedStatusBarang!,
          'kondisi': item.selectedKondisiBarang!,
          'keterangan': item.keteranganController.text.trim(),
        };
      }).toList();

      await inventoryRepository.addMultipleInventoryItems(items: items);
      final itemCount = event.items.length;
      emit(InventorySuccess('$itemCount item berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan items: $e'));
    }
  }

  Future<void> _onLoadItemBySerialForTransaction(
      LoadItemBySerialForTransaction event,
      Emitter<InventoryState> emit) async {
    try {
      final item = await inventoryRepository.getItemBySerial(event.serialNumber);
      if (item != null) {
        emit(ItemLoadedForTransaction(
          namaBarang: item.namaBarang ?? '',
          kategori: item.kategori ?? '',
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

  Future<void> _onAddMultipleTransactions(
      AddMultipleTransactions event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final transactions = event.transactions.map((transaction) {
        return {
          'nomorSerial': transaction.nomorSerialController.text.trim(),
          'namaBarang': transaction.namaBarangController.text.trim(),
          'kategori': transaction.selectedKategori!,
          'status': transaction.selectedStatus!,
          'kondisi': transaction.selectedKondisi!,
          'keterangan': transaction.keteranganController.text.trim(),
        };
      }).toList();

      await inventoryRepository.addMultipleTransactions(items: transactions);
      final transactionCount = event.transactions.length;
      emit(InventorySuccess('$transactionCount transaksi berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan transaksi: $e'));
    }
  }

  Future<void> _onEditInventory(
      InventoryEventEditInventory event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await inventoryRepository.editInventory(
        nomorSerial: event.nomorSerial,
        namaBarang: event.namaBarang,
        kategori: event.kategori,
      );
      emit(InventoryStateCompleteEdit('Data berhasil diperbarui'));
    } catch (e) {
      emit(InventoryError('Gagal mengupdate data: $e'));
    }
  }

  Future<void> _onAddTransaction(
      AddTransaction event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await inventoryRepository.addTransaction(
        nomorSerial: event.nomorSerial,
        namaBarang: event.namaBarang,
        kategori: event.kategori,
        status: event.status,
        kondisi: event.kondisi,
        keterangan: event.keterangan,
      );
      emit(InventorySuccess('Transaksi berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan transaksi: $e'));
    }
  }

  Future<void> _onDeleteInventoryItem(
      DeleteInventoryItem event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await inventoryRepository.deleteInventoryItem(event.nomorSerial);
      emit(InventorySuccess('Item berhasil dihapus'));
    } catch (e) {
      emit(InventoryError('Gagal menghapus item: $e'));
    }
  }

  Future<void> _onEditTransaction(
      InventoryEventEditTransaction event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await inventoryRepository.editTransaction(
        transactionId: event.id,
        status: event.status,
        kondisi: event.kondisi,
        keterangan: event.keterangan,
      );
      emit(InventoryStateCompleteEdit('Data transaksi berhasil diperbarui'));
    } catch (e) {
      emit(InventoryError('Gagal mengupdate transaksi: $e'));
    }
  }

  Future<void> _onDeleteTransaction(InventoryEventDeleteTransaction event,
      Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await inventoryRepository.deleteTransaction(event.id);
      emit(InventorySuccess('Data transaksi berhasil dihapus'));
    } catch (e) {
      emit(InventoryError('Gagal menghapus transaksi: $e'));
    }
  }

  Future<void> _onLoadItemBySerial(
      LoadItemBySerial event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final item = await inventoryRepository.getItemBySerial(event.serialNumber);
      if (item != null) {
        emit(ItemLoaded(
          namaBarang: item.namaBarang ?? '',
          kategori: item.kategori ?? '',
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
    try {
      final start = _dateFormatter.parse(startDate);
      final end = _dateFormatter.parse(endDate);

      final Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('inventory/transaction/items')
          .where("tanggal", isGreaterThanOrEqualTo: startDate)
          .where("tanggal", isLessThanOrEqualTo: endDate)
          .orderBy("tanggal", descending: true);

      await for (final snapshot in query.snapshots()) {
        final transactions = <Inventory>[];

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            final transaction = Inventory.fromJson(data);

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

            if (status != null && status != 'Semua Status') {
              if (transaction.status?.toLowerCase() != status.toLowerCase()) {
                continue;
              }
            }

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

  String getTodayDateFormatted() => _todayFormatted;
}
