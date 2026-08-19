import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/domain/repositories/carpool_repository.dart';
import 'package:inventrack/models/carpool.dart';

part 'carpool_event.dart';
part 'carpool_state.dart';

class CarpoolBloc extends Bloc<CarpoolEvent, CarpoolState> {
  final CarpoolRepository carpoolRepository;

  CarpoolBloc({required this.carpoolRepository}) : super(CarpoolStateInitial()) {
    on<CarpoolEventAdd>((event, emit) async {
      try {
        emit(CarpoolStateLoadingAdd());
        await carpoolRepository.addCarpool(
          namaPengguna: event.namaPengguna,
          satuanKerja: event.satuanKerja,
          tujuan: event.tujuan,
          keperluan: event.keperluan,
          jamBerangkat: event.jamBerangkat,
          jamKembali: event.jamKembali,
          kendaraan: event.kendaraan,
          pengemudi: event.pengemudi,
          kmAwal: event.kmAwal,
          statusDriver: event.statusDriver,
          namaPenumpang: event.namaPenumpang,
        );
        emit(CarpoolStateCompleteAdd());
      } on FirebaseException catch (e) {
        emit(CarpoolStateError(e.message ?? "Gagal Menambah Carpool"));
      } catch (e) {
        emit(CarpoolStateError("Terjadi kesalahan, coba lagi"));
      }
    });

    on<CarpoolEventAddRequest>((event, emit) async {
      try {
        emit(CarpoolStateLoadingAdd());
        await carpoolRepository.addCarpoolRequest(
          namaPengguna: event.namaPengguna,
          satuanKerja: event.satuanKerja,
          tujuan: event.tujuan,
          keperluan: event.keperluan,
          jamBerangkat: event.jamBerangkat,
          jamKembali: event.jamKembali,
          tanggalRequest: event.tanggalRequest,
          namaPenumpang: event.namaPenumpang,
        );
        emit(CarpoolStateCompleteAdd());
      } on FirebaseException catch (e) {
        emit(CarpoolStateError(e.message ?? "Gagal Menambah Carpool"));
      } catch (e) {
        emit(CarpoolStateError("Terjadi kesalahan, coba lagi"));
      }
    });
  }
}
