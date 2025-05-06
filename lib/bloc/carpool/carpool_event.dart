part of 'carpool_bloc.dart';

abstract class CarpoolEvent {}

class CarpoolEventAdd extends CarpoolEvent {
  final String namaPengguna;
  final String satuanKerja;
  final String tujuan;
  final String keperluan;
  final String jamBerangkat;
  final String jamKembali;
  final String kendaraan;
  final String pengemudi;
  final String kmAwal;
  final String statusDriver;
  final String? namaPenumpang;

  CarpoolEventAdd({
    required this.namaPengguna,
    required this.satuanKerja,
    required this.tujuan,
    required this.keperluan,
    required this.jamBerangkat,
    required this.jamKembali,
    required this.kendaraan,
    required this.pengemudi,
    required this.kmAwal,
    required this.statusDriver,
    required this.namaPenumpang,
  });
}

class CarpoolEventAddRequest extends CarpoolEvent {
  final String namaPengguna;
  final String satuanKerja;
  final String tujuan;
  final String keperluan;
  final String jamBerangkat;
  final String jamKembali;
  final String tanggalRequest;
  final String? namaPenumpang;

  CarpoolEventAddRequest({
    required this.namaPengguna,
    required this.satuanKerja,
    required this.tujuan,
    required this.keperluan,
    required this.jamBerangkat,
    required this.jamKembali,
    required this.tanggalRequest,
    required this.namaPenumpang,
  });
}

class CarpoolEventEditCarpool extends CarpoolEvent {
  final String namaPengguna;
  final String satuanKerja;
  final String tujuan;
  final String keperluan;
  final String jamBerangkat;
  final String jamKembali;
  final String kendaraan;
  final String pengemudi;
  final String kmAwal;
  final String kmAkhir;
  final String statusDriver;
  final String id;
  final String formattedDate;
  final String? namaPenumpang;

  CarpoolEventEditCarpool({
    required this.namaPengguna,
    required this.satuanKerja,
    required this.tujuan,
    required this.keperluan,
    required this.jamBerangkat,
    required this.jamKembali,
    required this.kendaraan,
    required this.pengemudi,
    required this.kmAwal,
    required this.kmAkhir,
    required this.statusDriver,
    required this.id,
    required this.formattedDate,
    required this.namaPenumpang,
  });
}

class CarpoolEventEditCarpoolRequest extends CarpoolEvent {
  final String namaPengguna;
  final String satuanKerja;
  final String tujuan;
  final String keperluan;
  final String jamBerangkat;
  final String jamKembali;
  final String kendaraan;
  final String pengemudi;
  final String kmAwal;
  final String kmAkhir;
  final String statusDriver;
  final String id;
  final String tanggalRequest;
  final String formattedDate;
  final String? namaPenumpang;

  CarpoolEventEditCarpoolRequest({
    required this.namaPengguna,
    required this.satuanKerja,
    required this.tujuan,
    required this.keperluan,
    required this.jamBerangkat,
    required this.jamKembali,
    required this.kendaraan,
    required this.pengemudi,
    required this.kmAwal,
    required this.kmAkhir,
    required this.statusDriver,
    required this.id,
    required this.tanggalRequest,
    required this.formattedDate,
    required this.namaPenumpang,
  });
}

class CarpoolEventFetch extends CarpoolEvent {}

class CarpoolEventDelete extends CarpoolEvent {
  final String id;
  final String formattedDate;

  CarpoolEventDelete(this.id, [this.formattedDate = '']);
}

class CarpoolEventDeleteRequest extends CarpoolEvent {
  final String id;
  final String formattedDate;

  CarpoolEventDeleteRequest(this.id, [this.formattedDate = '']);
}
