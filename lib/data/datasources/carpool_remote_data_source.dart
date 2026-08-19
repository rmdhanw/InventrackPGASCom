import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:inventrack/core/constants/firestore_constants.dart';

abstract class CarpoolRemoteDataSource {
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

class CarpoolRemoteDataSourceImpl implements CarpoolRemoteDataSource {
  final FirebaseFirestore firestore;
  final http.Client httpClient;

  CarpoolRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        httpClient = httpClient ?? http.Client();

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
    final now = DateTime.now();
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    final docRef = await firestore
        .collection(FirestoreConstants.carpoolCollection)
        .doc(formattedDate)
        .collection(FirestoreConstants.carpoolItemsSubcollection)
        .add({
      "namaPengguna": namaPengguna,
      "satuanKerja": satuanKerja,
      "tujuan": tujuan,
      "keperluan": keperluan,
      "jamBerangkat": jamBerangkat,
      "jamKembali": jamKembali,
      "kendaraan": kendaraan,
      "pengemudi": pengemudi,
      "kmAwal": kmAwal,
      "kmAkhir": null,
      "statusDriver": statusDriver,
      "createdAt": FieldValue.serverTimestamp(),
      "formattedDate": formattedDate,
      "namaPenumpang": namaPenumpang,
    });

    await docRef.update({"id": docRef.id});
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
    final now = DateTime.now();
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    final docRef = await firestore
        .collection(FirestoreConstants.carpoolCollection)
        .doc(formattedDate)
        .collection(FirestoreConstants.carpoolRequestSubcollection)
        .add({
      "namaPengguna": namaPengguna,
      "satuanKerja": satuanKerja,
      "tujuan": tujuan,
      "keperluan": keperluan,
      "jamBerangkat": jamBerangkat,
      "jamKembali": jamKembali,
      "kendaraan": null,
      "pengemudi": null,
      "kmAwal": null,
      "kmAkhir": null,
      "statusDriver": null,
      "createdAt": FieldValue.serverTimestamp(),
      "tanggalRequest": tanggalRequest,
      "formattedDate": formattedDate,
      "namaPenumpang": namaPenumpang,
    });

    await docRef.update({"id": docRef.id});

    await sendTelegramNotification(
      namaPengguna: namaPengguna,
      tujuan: tujuan,
      keperluan: keperluan,
      tanggalRequest: tanggalRequest,
    );
  }

  @override
  Future<void> sendTelegramNotification({
    required String namaPengguna,
    required String tujuan,
    required String keperluan,
    required String tanggalRequest,
  }) async {
    const String botToken = String.fromEnvironment(
      'TELEGRAM_BOT_TOKEN',
      defaultValue: '',
    );
    const String chatId = String.fromEnvironment(
      'TELEGRAM_CHAT_ID',
      defaultValue: '',
    );

    if (botToken.isEmpty || chatId.isEmpty) {
      // Ignored if credentials are not configured in environment
      return;
    }

    final String message = """
🚗 *Permintaan Operasional Carpool* 🚗

👤 *Nama Pengguna*: $namaPengguna
📍 *Tujuan*: $tujuan
🎯 *Keperluan*: $keperluan
📅 *Tanggal Permintaan*: $tanggalRequest
    """;

    final Uri url =
        Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");

    final response = await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "chat_id": chatId,
        "text": message,
        "parse_mode": "Markdown",
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal mengirim notifikasi Telegram");
    }
  }
}
