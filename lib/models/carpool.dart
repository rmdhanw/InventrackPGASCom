import 'package:cloud_firestore/cloud_firestore.dart';

class Carpool {
  String? namapengguna;
  String? satuanKerja;
  String? tujuan;
  String? keperluan;
  String? jamBerangkat;
  String? jamKembali;
  String? kendaraan;
  String? pengemudi;
  String? kmAwal;
  String? kmAkhir;
  String? statusDriver;
  DateTime? createdAt;
  String id;
  String formattedDate;
  String? tanggalRequest;
  String? namaPenumpang;

  Carpool({
    this.namapengguna,
    this.satuanKerja,
    this.tujuan,
    this.keperluan,
    this.jamBerangkat,
    this.jamKembali,
    this.kendaraan,
    this.pengemudi,
    this.kmAwal,
    this.kmAkhir,
    this.createdAt,
    required this.id,
    this.statusDriver,
    required this.formattedDate,
    this.tanggalRequest,
    this.namaPenumpang,
  });

  factory Carpool.fromJson(Map<String, dynamic> json) => Carpool(
        namapengguna: json["namaPengguna"] ?? "",
        satuanKerja: json["satuanKerja"] ?? "",
        tujuan: json["tujuan"] ?? "",
        keperluan: json["keperluan"] ?? "",
        jamBerangkat: json["jamBerangkat"] ?? "",
        jamKembali: json["jamKembali"] ?? "",
        kendaraan: json["kendaraan"] ?? "",
        pengemudi: json["pengemudi"] ?? "",
        kmAwal: json["kmAwal"] ?? "",
        kmAkhir: json["kmAkhir"] ?? "",
        statusDriver: json["statusDriver"] ?? "",
        createdAt: json["createdAt"] != null
            ? (json["createdAt"] as Timestamp).toDate()
            : null,
        id: json["id"] ?? "",
        formattedDate: json["formattedDate"] ?? "",
        tanggalRequest: json["tanggalRequest"] ?? "",
        namaPenumpang: json["namaPenumpang"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "namaPengguna": namapengguna,
        "satuanKerja": satuanKerja,
        "tujuan": tujuan,
        "keperluan": keperluan,
        "jamBerangkat": jamBerangkat,
        "jamKembali": jamKembali,
        "kendaraan": kendaraan,
        "pengemudi": pengemudi,
        "kmAwal": kmAwal,
        "kmAkhir": kmAkhir,
        "statusDriver": statusDriver,
        "createdAt": createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        "id": id,
        "formattedDate": formattedDate,
        "tanggalRequest": tanggalRequest,
        "namaPenumpang": namaPenumpang,
      };
}
