import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/domain/entities/carpool_entity.dart';

class Carpool extends CarpoolEntity {
  Carpool({
    super.namapengguna,
    super.satuanKerja,
    super.tujuan,
    super.keperluan,
    super.jamBerangkat,
    super.jamKembali,
    super.kendaraan,
    super.pengemudi,
    super.kmAwal,
    super.kmAkhir,
    super.createdAt,
    required super.id,
    super.statusDriver,
    required super.formattedDate,
    super.tanggalRequest,
    super.namaPenumpang,
    super.handle,
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
            ? (json["createdAt"] is Timestamp
                ? (json["createdAt"] as Timestamp).toDate()
                : json["createdAt"] as DateTime)
            : null,
        id: json["id"] ?? "",
        formattedDate: json["formattedDate"] ?? "",
        tanggalRequest: json["tanggalRequest"] ?? "",
        namaPenumpang: json["namaPenumpang"] ?? "",
        handle: json["handle"] ?? "",
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
        "handle": handle,
      };
}
