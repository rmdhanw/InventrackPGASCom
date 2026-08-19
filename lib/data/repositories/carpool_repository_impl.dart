import 'package:inventrack/data/datasources/carpool_remote_data_source.dart';
import 'package:inventrack/domain/repositories/carpool_repository.dart';

class CarpoolRepositoryImpl implements CarpoolRepository {
  final CarpoolRemoteDataSource remoteDataSource;

  CarpoolRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    await remoteDataSource.addCarpool(
      namaPengguna: namaPengguna,
      satuanKerja: satuanKerja,
      tujuan: tujuan,
      keperluan: keperluan,
      jamBerangkat: jamBerangkat,
      jamKembali: jamKembali,
      kendaraan: kendaraan,
      pengemudi: pengemudi,
      kmAwal: kmAwal,
      statusDriver: statusDriver,
      namaPenumpang: namaPenumpang,
    );
  }

  @override
  Future<void> addCarpoolRequest({
    required String namaPengguna,
    required String satuanKerja,
    required String tujuan,
    required String keperluan,
    required String jamBerangkat,
    required String jamKembali,
    required String tanggalRequest,
    String? namaPenumpang,
  }) async {
    await remoteDataSource.addCarpoolRequest(
      namaPengguna: namaPengguna,
      satuanKerja: satuanKerja,
      tujuan: tujuan,
      keperluan: keperluan,
      jamBerangkat: jamBerangkat,
      jamKembali: jamKembali,
      tanggalRequest: tanggalRequest,
      namaPenumpang: namaPenumpang,
    );
  }

  @override
  Future<void> sendTelegramNotification({
    required String namaPengguna,
    required String tujuan,
    required String keperluan,
    required String tanggalRequest,
  }) async {
    await remoteDataSource.sendTelegramNotification(
      namaPengguna: namaPengguna,
      tujuan: tujuan,
      keperluan: keperluan,
      tanggalRequest: tanggalRequest,
    );
  }
}
