class Carpool {
  //  "namaPengguna": event.namaPengguna,
  //         "satuanKerja": event.satuanKerja,
  //         "tujuan": event.tujuan,
  //         "jamBerangkat": event.jamBerangkat,
  //         "jamKembali": event.jamKembali,
  //         "kendaraan": event.kendaraan,
  //         "pengemudi": event.pengemudi,
  //         "kmAwal": event.kmAwal,
  //         "kmAkhir": event.kmAkhir,
  //         "createdAt": FieldValue.serverTimestamp(),

  String? namapengguna;
  String? satuanKerja;
  String? tujuan;
  String? jamBerangkat;
  String? jamKembali;
  String? kendaraan;
  String? pengemudi;
  String? kmAwal;
  String? kmAkhir;
  DateTime? createdAt;

  Carpool({
    this.namapengguna,
    this.satuanKerja,
    this.tujuan,
    this.jamBerangkat,
    this.jamKembali,
    this.kendaraan,
    this.pengemudi,
    this.kmAwal,
    this.kmAkhir,
    this.createdAt,
  });

  factory Carpool.fromJson(Map<String, dynamic> json) => Carpool(
        namapengguna: json["namaPengguna"] ?? "",
        satuanKerja: json["satuanKerja"] ?? "",
        tujuan: json["tujuan"] ?? "",
        jamBerangkat: json["jamBerangkat"] ?? "",
        jamKembali: json["jamKembali"] ?? "",
        kendaraan: json["kendaraan"] ?? "",
        pengemudi: json["pengemudi"] ?? "",
        kmAwal: json["kmAwal"] ?? "",
        kmAkhir: json["kmAkhir"] ?? "",
        createdAt: json["createdAt"] != null
            ? DateTime.fromMillisecondsSinceEpoch(json["createdAt"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "namaPengguna": namapengguna,
        "satuanKerja": satuanKerja,
        "tujuan": tujuan,
        "jamBerangkat": jamBerangkat,
        "jamKembali": jamKembali,
        "kendaraan": kendaraan,
        "pengemudi": pengemudi,
        "kmAwal": kmAwal,
        "kmAkhir": kmAkhir,
        "createdAt": createdAt?.millisecondsSinceEpoch,
      };
}
