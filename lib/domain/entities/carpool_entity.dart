class CarpoolEntity {
  final String id;
  final String? namapengguna;
  final String? satuanKerja;
  final String? tujuan;
  final String? keperluan;
  final String? jamBerangkat;
  final String? jamKembali;
  final String? kendaraan;
  final String? pengemudi;
  final String? kmAwal;
  final String? kmAkhir;
  final String? statusDriver;
  final DateTime? createdAt;
  final String formattedDate;
  final String? tanggalRequest;
  final String? namaPenumpang;
  final String? handle;

  const CarpoolEntity({
    required this.id,
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
    this.statusDriver,
    this.createdAt,
    required this.formattedDate,
    this.tanggalRequest,
    this.namaPenumpang,
    this.handle,
  });
}
