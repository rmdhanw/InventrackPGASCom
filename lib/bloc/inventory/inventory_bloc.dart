import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

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
  }

  // Load all available categories
  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      // Get unique categories from existing items
      final snapshot = await _firestore
          .collection("inventory")
          .doc("data")
          .collection("items")
          .get();

      // Extract unique categories from documents
      final Set<String> uniqueCategories = {};
      for (var doc in snapshot.docs) {
        if (doc.data().containsKey('kategori')) {
          uniqueCategories.add(doc['kategori'] as String);
        }
      }

      final List<String> kategoriList = uniqueCategories.toList()..sort();

      // Emit loaded state with categories
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

      // Reload categories after adding a new item
      add(LoadCategories());

      emit(InventorySuccess('Item berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan barang: $e'));
    }
  }

  // Add a transaction
  Future<void> _onAddTransaction(
      AddTransaction event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());

    try {
      final now = DateTime.now();
      final formattedDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      _firestore
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

      emit(InventorySuccess('Transaksi berhasil ditambahkan'));
    } catch (e) {
      emit(InventoryError('Gagal menambahkan transaksi: $e'));
    }
  }

  // Delete an inventory item
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

  // Load an item by serial number
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
}
