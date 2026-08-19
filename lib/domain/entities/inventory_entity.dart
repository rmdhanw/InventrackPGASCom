class InventoryEntity {
  final String id;
  final String? kategori;
  final String? namaBarang;
  final String? nomorSerial;
  final String? tanggal;
  final DateTime? timestamp;
  final String? kondisi;
  final String? status;
  final String? keterangan;

  const InventoryEntity({
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
}
