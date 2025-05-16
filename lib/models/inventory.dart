import 'package:cloud_firestore/cloud_firestore.dart';

class Inventory {
  String id;
  String? kategori;
  String? namaBarang;
  String? nomorSerial;
  String? tanggal;
  DateTime? timestamp;
  String? kondisi;
  String? status;
  String? keterangan;

  Inventory({
    required this.id,
    this.kategori,
    this.namaBarang,
    this.nomorSerial,
    this.tanggal,
    this.timestamp,
    this.kondisi,
    this.status,
    this.keterangan,
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
          ? (json['timestamp'] as dynamic).toDate()
          : null,
      kondisi: json['kondisi'],
      status: json['status'],
      keterangan: json['keterangan'],
    );
  }

  // Add a specific method for creating from Firestore DocumentSnapshot
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
      // We don't typically include timestamp in toJson as Firestore will handle it
    };
  }
}
