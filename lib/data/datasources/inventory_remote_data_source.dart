import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/core/constants/firestore_constants.dart';
import 'package:inventrack/models/inventory.dart';

abstract class InventoryRemoteDataSource {
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
  Future<Inventory?> getItemBySerial(String nomorSerial);
  Future<Inventory?> getItemBySerialForTransaction(String nomorSerial);
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

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore firestore;
  static final DateFormat _dateFormatter = DateFormat('dd-MM-yyyy');

  InventoryRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  String get _todayFormatted => _dateFormatter.format(DateTime.now());

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      firestore.collection(FirestoreConstants.inventoryDataPath);

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      firestore.collection(FirestoreConstants.inventoryTransactionPath);

  @override
  Future<List<String>> getCategories() async {
    final metaDoc =
        await firestore.doc(FirestoreConstants.inventoryCategoriesPath).get();

    if (metaDoc.exists && metaDoc.data()?['categories'] != null) {
      final List<dynamic> catList = metaDoc.data()!['categories'];
      return catList.cast<String>()..sort();
    }

    final snapshot = await _itemsCollection.get();
    final Set<String> uniqueCategories = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('kategori') && data['kategori'] != null) {
        uniqueCategories.add(data['kategori'] as String);
      }
    }

    final categories = uniqueCategories.toList()..sort();
    firestore.doc(FirestoreConstants.inventoryCategoriesPath).set({
      'categories': categories,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return categories;
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
    final batch = firestore.batch();

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
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> addMultipleInventoryItems({
    required List<Map<String, dynamic>> items,
  }) async {
    WriteBatch batch = firestore.batch();
    int operationCount = 0;

    for (var itemData in items) {
      final String nomorSerial = itemData['nomorSerial'] ?? '';
      if (nomorSerial.isEmpty) continue;

      final itemRef = _itemsCollection.doc(nomorSerial);
      batch.set(itemRef, {
        'kategori': itemData['kategori'] ?? '',
        'namaBarang': itemData['namaBarang'] ?? '',
        'nomorSerial': nomorSerial,
        'tanggal': _todayFormatted,
        'timestamp': FieldValue.serverTimestamp(),
      });
      operationCount++;

      final transactionRef = _transactionsCollection.doc();
      batch.set(transactionRef, {
        'id': transactionRef.id,
        'nomorSerial': nomorSerial,
        'kategori': itemData['kategori'] ?? '',
        'namaBarang': itemData['namaBarang'] ?? '',
        'status': itemData['status'] ?? '',
        'kondisi': itemData['kondisi'],
        'keterangan': itemData['keterangan'],
        'tanggal': _todayFormatted,
        'timestamp': FieldValue.serverTimestamp(),
      });
      operationCount++;

      if (operationCount >= 400) {
        await batch.commit();
        batch = firestore.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }
  }

  @override
  Future<Inventory?> getItemBySerial(String nomorSerial) async {
    final docSnapshot = await _itemsCollection.doc(nomorSerial).get();
    if (docSnapshot.exists) {
      return Inventory.fromFirestore(docSnapshot);
    }
    return null;
  }

  @override
  Future<Inventory?> getItemBySerialForTransaction(String nomorSerial) async {
    final querySnapshot = await _transactionsCollection
        .where('nomorSerial', isEqualTo: nomorSerial)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Inventory.fromFirestore(querySnapshot.docs.first);
    }
    return null;
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
    final transactionRef = _transactionsCollection.doc();
    await transactionRef.set({
      'id': transactionRef.id,
      'nomorSerial': nomorSerial,
      'kategori': kategori,
      'namaBarang': namaBarang,
      'status': status,
      'kondisi': kondisi,
      'keterangan': keterangan,
      'tanggal': _todayFormatted,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addMultipleTransactions({
    required List<Map<String, dynamic>> items,
  }) async {
    WriteBatch batch = firestore.batch();
    int operationCount = 0;

    for (var itemData in items) {
      final transactionRef = _transactionsCollection.doc();
      batch.set(transactionRef, {
        'id': transactionRef.id,
        'nomorSerial': itemData['nomorSerial'] ?? '',
        'kategori': itemData['kategori'] ?? '',
        'namaBarang': itemData['namaBarang'] ?? '',
        'status': itemData['status'] ?? '',
        'kondisi': itemData['kondisi'],
        'keterangan': itemData['keterangan'],
        'tanggal': _todayFormatted,
        'timestamp': FieldValue.serverTimestamp(),
      });
      operationCount++;

      if (operationCount >= 400) {
        await batch.commit();
        batch = firestore.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }
  }

  @override
  Future<void> deleteInventoryItem(String nomorSerial) async {
    final batch = firestore.batch();
    final itemRef = _itemsCollection.doc(nomorSerial);
    batch.delete(itemRef);

    final transactionsQuery = await _transactionsCollection
        .where('nomorSerial', isEqualTo: nomorSerial)
        .get();

    for (var doc in transactionsQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  @override
  Future<void> editInventory({
    required String nomorSerial,
    required String namaBarang,
    required String kategori,
  }) async {
    final batch = firestore.batch();
    final itemRef = _itemsCollection.doc(nomorSerial);
    batch.update(itemRef, {
      'namaBarang': namaBarang,
      'kategori': kategori,
    });

    final transactionsQuery = await _transactionsCollection
        .where('nomorSerial', isEqualTo: nomorSerial)
        .get();

    for (var doc in transactionsQuery.docs) {
      batch.update(doc.reference, {
        'namaBarang': namaBarang,
        'kategori': kategori,
      });
    }

    await batch.commit();
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsCollection.doc(transactionId).delete();
  }

  @override
  Future<void> editTransaction({
    required String transactionId,
    required String status,
    String? kondisi,
    String? keterangan,
  }) async {
    await _transactionsCollection.doc(transactionId).update({
      'status': status,
      'kondisi': kondisi,
      'keterangan': keterangan,
    });
  }
}
