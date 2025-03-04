import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/models/carpool.dart';

part 'carpool_event.dart';
part 'carpool_state.dart';

class CarpoolBloc extends Bloc<CarpoolEvent, CarpoolState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Carpool>> streamProducts() async* {
    yield* firestore
        .collection("carpool_requests")
        .withConverter<Carpool>(
          fromFirestore: (snapshot, _) => Carpool.fromJson(snapshot.data()!),
          toFirestore: (product, _) => product.toJson(),
        )
        .snapshots();
  }

  CarpoolBloc() : super(CarpoolStateInitial()) {
    on<CarpoolEventAdd>((event, emit) async {
      try {
        emit(CarpoolStateLoadingAdd());
        var hasil = await firestore.collection("carpool_requests").add({
          "namaPengguna": event.namaPengguna,
          "satuanKerja": event.satuanKerja,
          "tujuan": event.tujuan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": event.kendaraan,
          "pengemudi": event.pengemudi,
          "kmAwal": event.kmAwal,
          "kmAkhir": event.kmAkhir,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await firestore
            .collection("carpool_requests")
            .doc(hasil.id)
            .update({"id": hasil.id});

        emit(CarpoolStateCompleteAdd());
      } on FirebaseException catch (e) {
        emit(CarpoolStateError(e.message ?? "Gagal menyimpan data"));
      } catch (e) {
        emit(CarpoolStateError("Terjadi kesalahan, coba lagi"));
      }
    });
  }
}
