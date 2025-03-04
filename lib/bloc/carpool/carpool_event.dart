part of 'carpool_bloc.dart';

abstract class CarpoolEvent {}

class CarpoolEventAdd extends CarpoolEvent {
  final String namaPengguna;
  final String satuanKerja;
  final String tujuan;
  final String jamBerangkat;
  final String jamKembali;
  final String kendaraan;
  final String pengemudi;
  final String kmAwal;
  final String kmAkhir;

  CarpoolEventAdd({
    required this.namaPengguna,
    required this.satuanKerja,
    required this.tujuan,
    required this.jamBerangkat,
    required this.jamKembali,
    required this.kendaraan,
    required this.pengemudi,
    required this.kmAwal,
    required this.kmAkhir,
  });
}

class CarpoolEventFetch extends CarpoolEvent {}

class CarpoolEventDelete extends CarpoolEvent {
  final String id;
  CarpoolEventDelete(this.id);
}
