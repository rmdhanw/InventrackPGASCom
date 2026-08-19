abstract class CarpoolRepository {
  Future<void> addCarpool({
    required String namaPengguna,
    required String satuanKerja,
    required String tujuan,
    required String keperluan,
    required String jamBerangkat,
    required String jamKembali,
    required String kendaraan,
    required String pengemudi,
    required String kmAwal,
    required String statusDriver,
    String? namaPenumpang,
  });

  Future<void> addCarpoolRequest({
    required String namaPengguna,
    required String satuanKerja,
    required String tujuan,
    required String keperluan,
    required String jamBerangkat,
    required String jamKembali,
    required String tanggalRequest,
    String? namaPenumpang,
  });

  Future<void> sendTelegramNotification({
    required String namaPengguna,
    required String tujuan,
    required String keperluan,
    required String tanggalRequest,
  });
}
