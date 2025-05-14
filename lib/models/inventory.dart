class Inventory {
  String? id;
  String? kategori;
  String? namaBarang;
  String? nomorSerial;
  String? tanggal;
  DateTime? timestamp;

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
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kategori': kategori,
      'namaBarang': namaBarang,
      'nomorSerial': nomorSerial,
      'tanggal': tanggal,
      // We don't typically include timestamp in toJson as Firestore will handle it
    };
  }
}
