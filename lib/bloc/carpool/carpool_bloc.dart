import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:http/http.dart' as http;

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
          "keperluan": event.keperluan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": event.kendaraan,
          "pengemudi": event.pengemudi,
          "kmAwal": event.kmAwal,
          "kmAkhir": null,
          "statusDriver": event.statusDriver,
          "createdAt": FieldValue.serverTimestamp(),
          "formattedDate": formattedDate,
          "namaPenumpang": event.namaPenumpang,
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
          "keperluan": event.keperluan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": null,
          "pengemudi": null,
          "kmAwal": null,
          "kmAkhir": null,
          "statusDriver": null,
          "createdAt": FieldValue.serverTimestamp(),
          "tanggalRequest": event.tanggalRequest,
          "formattedDate": formattedDate,
          "namaPenumpang": event.namaPenumpang,
        });

        await docRef.update({"id": docRef.id});

        await sendTelegramNotification(
          namaPengguna: event.namaPengguna,
          tujuan: event.tujuan,
          keperluan: event.keperluan,
          tanggalRequest: event.tanggalRequest,
        );

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

        // Coba ambil dengan path lengkap jika formattedDate tersedia
        if (event.formattedDate.isNotEmpty) {
          try {
            final docRef = firestore
                .collection("carpool")
                .doc(event.formattedDate)
                .collection("carpoolItems")
                .doc(event.id);

            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              await docRef.update({
                "namaPengguna": event.namaPengguna,
                "satuanKerja": event.satuanKerja,
                "tujuan": event.tujuan,
                "keperluan": event.keperluan,
                "jamBerangkat": event.jamBerangkat,
                "jamKembali": event.jamKembali,
                "kendaraan": event.kendaraan,
                "pengemudi": event.pengemudi,
                "kmAwal": event.kmAwal,
                "kmAkhir": event.kmAkhir,
                "statusDriver": event.statusDriver,
                "namaPenumpang": event.namaPenumpang,
              });

              emit(CarpoolStateCompleteEdit());
              return;
            } else {}
          } catch (e) {
            // Lanjutkan ke collectionGroup jika direct path gagal
          }
        }

        // Fallback ke collectionGroup
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
          "keperluan": event.keperluan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": event.kendaraan,
          "pengemudi": event.pengemudi,
          "kmAwal": event.kmAwal,
          "kmAkhir": event.kmAkhir,
          "statusDriver": event.statusDriver,
          "namaPenumpang": event.namaPenumpang,
        });

        emit(CarpoolStateCompleteEdit());
      } catch (e) {
        emit(CarpoolStateError("Tidak dapat merubah carpool: $e"));
      }
    });

    on<CarpoolEventEditCarpoolRequest>((event, emit) async {
      try {
        emit(CarpoolStateLoadingEdit());

        final deletedate = event.formattedDate;

        final docRef = firestore
            .collection("carpool")
            .doc(event.tanggalRequest)
            .collection("carpoolItems")
            .doc(event.id);

        await docRef.set({
          "id": event.id,
          "namaPengguna": event.namaPengguna,
          "satuanKerja": event.satuanKerja,
          "tujuan": event.tujuan,
          "keperluan": event.keperluan,
          "jamBerangkat": event.jamBerangkat,
          "jamKembali": event.jamKembali,
          "kendaraan": event.kendaraan,
          "pengemudi": event.pengemudi,
          "kmAwal": event.kmAwal,
          "kmAkhir": null,
          "statusDriver": event.statusDriver,
          "createdAt": FieldValue.serverTimestamp(),
          "formattedDate": event.tanggalRequest,
          "namaPenumpang": event.namaPenumpang,
        });

        if (deletedate.isNotEmpty) {
          final oldDocRef = firestore
              .collection("carpool")
              .doc(deletedate)
              .collection("carpoolRequest")
              .doc(event.id);

          final docSnapshot = await oldDocRef.get();
          if (docSnapshot.exists) {
            await oldDocRef.delete();
          }
        }

        emit(CarpoolStateCompleteEdit());
      } on FirebaseException catch (e) {
        emit(CarpoolStateError(e.message ?? "Tidak dapat memindahkan Carpool"));
      } catch (e) {
        emit(CarpoolStateError("Terjadi kesalahan saat edit carpool: $e"));
      }
    });

    on<CarpoolEventDelete>((event, emit) async {
      try {
        emit(CarpoolStateLoadingDelete());

        if (event.formattedDate.isNotEmpty) {
          try {
            final docRef = firestore
                .collection("carpool")
                .doc(event.formattedDate)
                .collection("carpoolItems")
                .doc(event.id);

            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              await docRef.delete();
              emit(CarpoolStateCompleteDelete());
              return;
            }
          } catch (e) {
            // Fallback ke collectionGroup jika gagal
          }
        }

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

    on<CarpoolEventDeleteRequest>((event, emit) async {
      try {
        emit(CarpoolStateLoadingDelete());

        if (event.formattedDate.isNotEmpty) {
          try {
            final docRef = firestore
                .collection("carpool")
                .doc(event.formattedDate)
                .collection("carpoolRequest")
                .doc(event.id);

            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              await docRef.delete();
              emit(CarpoolStateCompleteDelete());
              return;
            }
          } catch (e) {
            // Fallback ke collectionGroup jika gagal
          }
        }
        await firestore
            .collectionGroup("carpoolRequest")
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

  Future<QuerySnapshot<Carpool>> getCarpoolByDate(String formattedDate) {
    return firestore
        .collection("carpool")
        .doc(formattedDate)
        .collection("carpoolItems")
        .orderBy("createdAt", descending: true)
        .withConverter<Carpool>(
          fromFirestore: (snapshot, _) => Carpool.fromJson(snapshot.data()!),
          toFirestore: (carpool, _) => carpool.toJson(),
        )
        .get();
  }

  Future<List<Carpool>> getCarpoolInDateRange(
      String startDate, String endDate) async {
    List<Carpool> allCarpool = [];

    DateTime start = DateFormat('dd-MM-yyyy').parse(startDate);
    DateTime end = DateFormat('dd-MM-yyyy').parse(endDate);

    for (DateTime date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(date);

      try {
        QuerySnapshot<Carpool> snapshot = await getCarpoolByDate(formattedDate);
        if (snapshot.docs.isNotEmpty) {
          allCarpool.addAll(snapshot.docs.map((e) => e.data()).toList());
        }
      } catch (e) {
        debugPrint('Error loading data for date $formattedDate: $e');
      }
    }

    return allCarpool;
  }

  Future<void> sendTelegramNotification({
    required String namaPengguna,
    required String tujuan,
    required String keperluan,
    required String tanggalRequest,
  }) async {
    try {
      // Konfigurasi Bot Telegram
      final String botToken =
          '8199363432:AAGQu86mQUmHSzEvfRvFk6cgnwSR9G67SxI'; // Token bot Telegram
      final String chatId =
          '855661090'; // Ganti dengan ID chat tujuan (user baru)

      // Format pesan notifikasi
      final String message = '''
*NOTIFIKASI PERMINTAAN CARPOOL BARU*

*Nama Pengguna:* $namaPengguna
*Tujuan:* $tujuan
*Keperluan:* $keperluan
*Tanggal Request:* $tanggalRequest

Silakan periksa aplikasi untuk detail lebih lanjut.
''';

      // Menggunakan API Telegram
      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Gagal mengirim notifikasi Telegram: ${response.body}');
      } else {
        debugPrint('Notifikasi Telegram berhasil dikirim');
      }
    } catch (e) {
      debugPrint('Error saat mengirim notifikasi Telegram: $e');
    }
  }
}
