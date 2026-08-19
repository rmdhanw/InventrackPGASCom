import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/domain/entities/inventory_entity.dart';

class Inventory extends InventoryEntity {
  Inventory({
    required super.id,
    super.kategori,
    super.namaBarang,
    super.nomorSerial,
    super.tanggal,
    super.timestamp,
    super.kondisi,
    super.status,
    super.keterangan,
  });

  // Regular fromJson method
  factory Inventory.fromJson(Map<String, dynamic> json, {String? docID}) {
    return Inventory(
      id: docID ?? json['id'] ?? '',
      kategori: json['kategori'],
      namaBarang: json['namaBarang'],
      nomorSerial: json['nomorSerial'],
      tanggal: json['tanggal'],
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is Timestamp
              ? (json['timestamp'] as Timestamp).toDate()
              : json['timestamp'] as DateTime)
          : null,
      kondisi: json['kondisi'],
      status: json['status'],
      keterangan: json['keterangan'],
    );
  }

  factory Inventory.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return Inventory.fromJson(data, docID: snapshot.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kondisi': kondisi,
      'status': status,
      'keterangan': keterangan,
      'kategori': kategori,
      'namaBarang': namaBarang,
      'nomorSerial': nomorSerial,
      'tanggal': tanggal,
    };
  }
}
