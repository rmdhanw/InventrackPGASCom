import 'package:cloud_firestore/cloud_firestore.dart';

// Update the Inventory model to match your Firestore structure
class Inventory {
  String? id;
  String? kategori;
  String? namaBarang;
  String? nomorSerial;
  String? tanggal;
  Timestamp? timestamp;

  Inventory({
    this.id,
    this.kategori,
    this.namaBarang,
    this.nomorSerial,
    this.tanggal,
    this.timestamp,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      kategori: json['kategori'],
      namaBarang: json['namaBarang'],
      nomorSerial: json['nomorSerial'],
      tanggal: json['tanggal'],
      timestamp: json['timestamp'],
    );
  }
}
