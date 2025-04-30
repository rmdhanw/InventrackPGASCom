import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/models/carpool.dart';

part 'carpool_event.dart';
part 'carpool_state.dart';

class CarpoolBloc extends Bloc<CarpoolEvent, CarpoolState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  CarpoolBloc() : super(CarpoolStateInitial()) {
    on<CarpoolEventAdd>((event, emit) async {
      try {
        emit(CarpoolStateLoadingAdd());

        final now = DateTime.now();
        final formattedDate =
            "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

        final docRef = await firestore
            .collection("carpool")
            .doc(formattedDate)
            .collection("carpoolItems")
            .add({
          "namaPengguna": event.namaPengguna,
          "satuanKerja": event.satuanKerja,
          "tujuan": event.tujuan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": event.kendaraan,
          "pengemudi": event.pengemudi,
          "kmAwal": event.kmAwal,
          "kmAkhir": "-",
          "statusDriver": event.statusDriver,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await docRef.update({"id": docRef.id});

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

        final now = DateTime.now();
        final formattedDate =
            "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

        final docRef = await firestore
            .collection("carpool")
            .doc(formattedDate)
            .collection("carpoolRequest")
            .add({
          "namaPengguna": event.namaPengguna,
          "satuanKerja": event.satuanKerja,
          "tujuan": event.tujuan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": "-",
          "pengemudi": "-",
          "kmAwal": "-",
          "kmAkhir": "-",
          "statusDriver": "-",
          "createdAt": FieldValue.serverTimestamp(),
        });

        await docRef.update({"id": docRef.id});

        emit(CarpoolStateCompleteAdd());
      } on FirebaseException catch (e) {
        emit(CarpoolStateError(e.message ?? "Gagal Menambah Carpool"));
      } catch (e) {
        emit(CarpoolStateError("Terjadi kesalahan, coba lagi"));
      }
    });

    on<CarpoolEventEditCarpool>((event, emit) async {
      try {
        emit(CarpoolStateLoadingEdit());
        final QuerySnapshot querySnapshot = await firestore
            .collectionGroup("carpoolItems")
            .where("id", isEqualTo: event.id)
            .get();

        if (querySnapshot.docs.isEmpty) {
          emit(CarpoolStateError("Document not found with ID: ${event.id}"));
          return;
        }
        final docRef = querySnapshot.docs[0].reference;

        await docRef.update({
          "namaPengguna": event.namaPengguna,
          "satuanKerja": event.satuanKerja,
          "tujuan": event.tujuan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": event.kendaraan,
          "pengemudi": event.pengemudi,
          "kmAwal": event.kmAwal,
          "kmAkhir": event.kmAkhir,
          "statusDriver": event.statusDriver,
        });

        emit(CarpoolStateCompleteEdit());
      } catch (e) {
        emit(CarpoolStateError("Tidak dapat merubah carpool: $e"));
      }
    });

    on<CarpoolEventDelete>((event, emit) async {
      try {
        emit(CarpoolStateLoadingDelete());
        await firestore
            .collectionGroup("carpoolItems")
            .where("id", isEqualTo: event.id)
            .get()
            .then((snapshot) async {
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
          }
        });

        emit(CarpoolStateCompleteDelete());
      } on FirebaseException catch (e) {
        emit(CarpoolStateError(e.message ?? "Gagal menghapus carpool"));
      } catch (e) {
        emit(CarpoolStateError("Terjadi kesalahan, coba lagi"));
      }
    });
  }

  Stream<QuerySnapshot<Carpool>> streamCarpoolByDate(String formattedDate) {
    return firestore
        .collection("carpool")
        .doc(formattedDate)
        .collection("carpoolItems")
        .orderBy("createdAt", descending: true)
        .withConverter<Carpool>(
          fromFirestore: (snapshot, _) => Carpool.fromJson(snapshot.data()!),
          toFirestore: (carpool, _) => carpool.toJson(),
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Carpool>> streamCarpoolRequestByDate(
      String formattedDate) {
    return firestore
        .collection("carpool")
        .doc(formattedDate)
        .collection("carpoolRequest")
        .orderBy("createdAt", descending: true)
        .withConverter<Carpool>(
          fromFirestore: (snapshot, _) => Carpool.fromJson(snapshot.data()!),
          toFirestore: (carpool, _) => carpool.toJson(),
        )
        .snapshots();
  }

  Stream<QuerySnapshot> getDriversByDate(String formattedDate) {
    return firestore
        .collection("carpool")
        .doc(formattedDate)
        .collection("carpoolItems")
        .snapshots();
  }

  String getTodayDateFormatted() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }
}
