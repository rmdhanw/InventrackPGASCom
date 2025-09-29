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

        // Kirim notifikasi Telegram setelah konfirmasi berhasil
        await sendTelegramConfirmationNotification(
          namaPengguna: event.namaPengguna,
          namaDriver: event.pengemudi,
          tujuan: event.tujuan,
          keperluan: event.keperluan,
          jamBerangkat: event.jamBerangkat,
          jamKembali: event.jamKembali,
          tanggalRequest: event.tanggalRequest,
          kendaraan: event.kendaraan,
        );

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

  Future<void> sendTelegramConfirmationNotification({
    required String namaPengguna,
    required String namaDriver,
    required String tujuan,
    required String keperluan,
    required String jamBerangkat,
    required String jamKembali,
    required String tanggalRequest,
    required String kendaraan,
  }) async {
    try {
      final String botToken = '8199363432:AAGQu86mQUmHSzEvfRvFk6cgnwSR9G67SxI';

      // Ambil chat ID pengguna berdasarkan nama
      String? userChatId = await getUserChatId(namaPengguna);

      // Ambil chat ID driver berdasarkan nama
      String? driverChatId = await getDriverChatId(namaDriver);

      // Pesan untuk pengguna
      final String userMessage = '''
*✅ PERMINTAAN CARPOOL ANDA DIKONFIRMASI*

*Nama Pengguna:* $namaPengguna
*Tujuan:* $tujuan
*Keperluan:* $keperluan
*Tanggal:* $tanggalRequest
*Jam Berangkat:* $jamBerangkat
*Jam Kembali:* $jamKembali
*Driver:* $namaDriver
*Kendaraan:* $kendaraan

Silakan bersiap sesuai jadwal yang telah ditentukan.
''';

      // Pesan untuk driver
      final String driverMessage = '''
*🚗 TUGAS CARPOOL BARU*

*Pengguna:* $namaPengguna
*Tujuan:* $tujuan
*Keperluan:* $keperluan
*Tanggal:* $tanggalRequest
*Jam Berangkat:* $jamBerangkat
*Jam Kembali:* $jamKembali
*Kendaraan:* $kendaraan

Anda telah ditugaskan sebagai driver untuk perjalanan ini.
''';

      // Kirim notifikasi ke pengguna jika chat ID ditemukan
      if (userChatId != null && userChatId.isNotEmpty) {
        await http.post(
          Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'chat_id': userChatId,
            'text': userMessage,
            'parse_mode': 'Markdown',
          }),
        );
        debugPrint(
            'Notifikasi konfirmasi berhasil dikirim ke pengguna: $namaPengguna');
      } else {
        debugPrint('Chat ID pengguna $namaPengguna tidak ditemukan');
      }

      // Kirim notifikasi ke driver jika chat ID ditemukan dan driver bukan '-'
      if (driverChatId != null &&
          driverChatId.isNotEmpty &&
          namaDriver != '-') {
        await http.post(
          Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'chat_id': driverChatId,
            'text': driverMessage,
            'parse_mode': 'Markdown',
          }),
        );
        debugPrint('Notifikasi tugas berhasil dikirim ke driver: $namaDriver');
      } else {
        debugPrint(
            'Chat ID driver $namaDriver tidak ditemukan atau driver tidak dipilih');
      }
    } catch (e) {
      debugPrint('Error saat mengirim notifikasi konfirmasi Telegram: $e');
    }
  }

  // Fungsi untuk mendapatkan chat ID pengguna berdasarkan nama
  Future<String?> getUserChatId(String namaPengguna) async {
    try {
      // Cari di collection Engineer terlebih dahulu
      QuerySnapshot engineerSnapshot = await firestore
          .collection("roles")
          .doc("Engineer")
          .collection("users")
          .where("name", isEqualTo: namaPengguna)
          .get();

      if (engineerSnapshot.docs.isNotEmpty) {
        final data = engineerSnapshot.docs.first.data() as Map<String, dynamic>;
        return data['chatid']?.toString();
      }

      // Jika tidak ditemukan di Engineer, cari di Driver
      QuerySnapshot driverSnapshot = await firestore
          .collection("roles")
          .doc("Driver")
          .collection("users")
          .where("name", isEqualTo: namaPengguna)
          .get();

      if (driverSnapshot.docs.isNotEmpty) {
        final data = driverSnapshot.docs.first.data() as Map<String, dynamic>;
        return data['chatid']?.toString();
      }

      return null;
    } catch (e) {
      debugPrint('Error mendapatkan chat ID pengguna: $e');
      return null;
    }
  }

  // Fungsi untuk mendapatkan chat ID driver berdasarkan nama
  Future<String?> getDriverChatId(String namaDriver) async {
    try {
      if (namaDriver == '-' || namaDriver.isEmpty) return null;

      QuerySnapshot snapshot = await firestore
          .collection("roles")
          .doc("Driver")
          .collection("users")
          .where("name", isEqualTo: namaDriver)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return data['chatid']?.toString();
      }

      return null;
    } catch (e) {
      debugPrint('Error mendapatkan chat ID driver: $e');
      return null;
    }
  }
}
