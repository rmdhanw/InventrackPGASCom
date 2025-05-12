import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'carpool_event.dart';
part 'carpool_state.dart';

class CarpoolBloc extends Bloc<CarpoolEvent, CarpoolState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Cache data
  final Map<String, List<Carpool>> _carpoolCache = {};
  DateTime _lastCacheUpdate = DateTime.now();
  final Duration _cacheExpiryDuration = const Duration(minutes: 30);
  bool _isListeningForChanges = false;

  CarpoolBloc() : super(CarpoolStateInitial()) {
    _initCacheFromPrefs();

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

        // Invalidate cache for this date
        _invalidateCache(formattedDate);

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

              // Invalidate cache for this date
              _invalidateCache(event.formattedDate);

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
        final String path = docRef.path;
        final String dateFromPath =
            path.split('/')[1]; // Extract date from path

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

        // Invalidate cache for this date
        _invalidateCache(dateFromPath);

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

        // Invalidate cache for both dates
        _invalidateCache(event.tanggalRequest);
        if (deletedate.isNotEmpty) {
          _invalidateCache(deletedate);
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

              // Invalidate cache for this date
              _invalidateCache(event.formattedDate);

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
            final String path = doc.reference.path;
            final String dateFromPath =
                path.split('/')[1]; // Extract date from path

            await doc.reference.delete();

            // Invalidate cache for this date
            _invalidateCache(dateFromPath);
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

    // Menambahkan event untuk mendapatkan data bulan
    on<CarpoolEventLoadMonthData>((event, emit) async {
      emit(CarpoolStateLoadingData());
      try {
        final data = await getCarpoolDataForMonth(event.year ?? 0, event.month);
        emit(CarpoolStateDataLoaded(data));
      } catch (e) {
        emit(CarpoolStateError("Gagal memuat data bulan: $e"));
      }
    });
  }

  // Inisialisasi cache dari SharedPreferences
  Future<void> _initCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cacheJson = prefs.getString('carpool_cache');
      final String? lastUpdateStr =
          prefs.getString('carpool_cache_last_update');

      if (cacheJson != null && lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        _lastCacheUpdate = lastUpdate;

        final Map<String, dynamic> cacheMap = jsonDecode(cacheJson);
        cacheMap.forEach((key, value) {
          final List<dynamic> items = value;
          _carpoolCache[key] = items
              .map((item) => Carpool.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        });

        debugPrint(
            'Cache loaded from SharedPreferences with ${_carpoolCache.length} entries');
      }
    } catch (e) {
      debugPrint('Error loading cache from SharedPreferences: $e');
    }
  }

  // Menyimpan cache ke SharedPreferences
  Future<void> _saveCacheToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert cache to json-serializable format
      final Map<String, List<Map<String, dynamic>>> serializableCache = {};
      _carpoolCache.forEach((key, value) {
        serializableCache[key] =
            value.map((carpool) => carpool.toJson()).toList();
      });

      await prefs.setString('carpool_cache', jsonEncode(serializableCache));
      await prefs.setString(
          'carpool_cache_last_update', _lastCacheUpdate.toIso8601String());

      debugPrint(
          'Cache saved to SharedPreferences with ${_carpoolCache.length} entries');
    } catch (e) {
      debugPrint('Error saving cache to SharedPreferences: $e');
    }
  }

  // Menghapus cache untuk tanggal tertentu
  void _invalidateCache(String date) {
    if (_carpoolCache.containsKey(date)) {
      _carpoolCache.remove(date);
      _saveCacheToPrefs(); // Update persistent storage
      debugPrint('Cache invalidated for date: $date');
    }
  }

  // Check if cache is valid
  bool _isCacheValid() {
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate) < _cacheExpiryDuration;
  }

  // Set up listener for real-time updates
  void _setupRealtimeListener(String formattedDate) {
    if (_isListeningForChanges) return;

    _isListeningForChanges = true;

    firestore
        .collection("carpool")
        .doc(formattedDate)
        .collection("carpoolItems")
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        debugPrint('Real-time update detected for date: $formattedDate');
        _invalidateCache(formattedDate);
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

  // Mendapatkan data carpools untuk satu bulan dengan dukungan caching
  Future<Map<DateTime, List<Carpool>>> getCarpoolDataForMonth(
      int year, int month) async {
    Map<DateTime, List<Carpool>> result = {};

    // Hitung first dan last day of month
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);

    // Format tanggal untuk range
    String startDateStr = _formatDate(firstDayOfMonth);
    String endDateStr = _formatDate(lastDayOfMonth);

    List<String> dateRange = _getDateRange(startDateStr, endDateStr);

    // Setup listener untuk update real-time jika belum
    if (!_isListeningForChanges) {
      _setupRealtimeListener(startDateStr);
    }

    // Check if we need to update the cache
    bool needsUpdate = !_isCacheValid();

    for (String date in dateRange) {
      // Check if we have valid cached data for this date
      if (!needsUpdate && _carpoolCache.containsKey(date)) {
        List<Carpool> cachedCarpools = _carpoolCache[date]!;
        DateTime dateKey = _parseDate(date);
        result[DateTime(dateKey.year, dateKey.month, dateKey.day)] =
            cachedCarpools;
        continue;
      }

      // No valid cache, fetch from Firestore
      try {
        QuerySnapshot<Carpool> snapshot = await firestore
            .collection("carpool")
            .doc(date)
            .collection("carpoolItems")
            .orderBy("createdAt", descending: true)
            .withConverter<Carpool>(
              fromFirestore: (snapshot, _) =>
                  Carpool.fromJson(snapshot.data()!),
              toFirestore: (carpool, _) => carpool.toJson(),
            )
            .get();

        if (snapshot.docs.isNotEmpty) {
          List<Carpool> carpools = snapshot.docs.map((e) => e.data()).toList();

          // Save to cache
          _carpoolCache[date] = carpools;

          // Add to result
          DateTime dateKey = _parseDate(date);
          result[DateTime(dateKey.year, dateKey.month, dateKey.day)] = carpools;
        }
      } catch (e) {
        debugPrint('Error loading data for date $date: $e');
      }
    }

    // Update cache timestamp
    _lastCacheUpdate = DateTime.now();

    // Save cache to persistent storage
    _saveCacheToPrefs();

    return result;
  }

  Future<QuerySnapshot<Carpool>> getCarpoolByDate(String formattedDate) async {
    // Check if we have valid cached data for this date
    if (_carpoolCache.containsKey(formattedDate) && _isCacheValid()) {
      debugPrint('Using cached data for date: $formattedDate');
      // Create a fake QuerySnapshot with the cached data
      // This is a bit hacky but allows us to keep the same return type
      // In a real implementation, you might want to refactor to return a List<Carpool> instead
      // and adjust the calling code accordingly

      // For now, we'll just fetch from Firestore instead of complicating the code
    }

    // Setup listener for this date if not already listening
    if (!_isListeningForChanges) {
      _setupRealtimeListener(formattedDate);
    }

    // Fetch from Firestore
    final snapshot = await firestore
        .collection("carpool")
        .doc(formattedDate)
        .collection("carpoolItems")
        .orderBy("createdAt", descending: true)
        .withConverter<Carpool>(
          fromFirestore: (snapshot, _) => Carpool.fromJson(snapshot.data()!),
          toFirestore: (carpool, _) => carpool.toJson(),
        )
        .get();

    // Update cache with the fetched data
    if (snapshot.docs.isNotEmpty) {
      _carpoolCache[formattedDate] =
          snapshot.docs.map((e) => e.data()).toList();
      _saveCacheToPrefs();
    }

    return snapshot;
  }

  Future<List<Carpool>> getCarpoolInDateRange(
      String startDate, String endDate) async {
    List<Carpool> allCarpool = [];

    DateTime start = DateFormat('dd-MM-yyyy').parse(startDate);
    DateTime end = DateFormat('dd-MM-yyyy').parse(endDate);

    List<String> dateRange = _getDateRange(startDate, endDate);

    for (String date in dateRange) {
      // Check if we have valid cached data for this date
      if (_carpoolCache.containsKey(date) && _isCacheValid()) {
        allCarpool.addAll(_carpoolCache[date]!);
        continue;
      }

      try {
        QuerySnapshot<Carpool> snapshot = await getCarpoolByDate(date);
        if (snapshot.docs.isNotEmpty) {
          List<Carpool> carpools = snapshot.docs.map((e) => e.data()).toList();
          _carpoolCache[date] = carpools; // Update cache
          allCarpool.addAll(carpools);
        }
      } catch (e) {
        debugPrint('Error loading data for date $date: $e');
      }
    }

    // Update cache timestamp and save
    _lastCacheUpdate = DateTime.now();
    _saveCacheToPrefs();

    return allCarpool;
  }

  DateTime _parseDate(String date) {
    List<String> parts = date.split('-');
    return DateTime(
      int.parse(parts[2]), // tahun
      int.parse(parts[1]), // bulan
      int.parse(parts[0]), // hari
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  List<String> _getDateRange(String start, String end) {
    List<String> dates = [];
    DateTime startDate = DateFormat('dd-MM-yyyy').parse(start);
    DateTime endDate = DateFormat('dd-MM-yyyy').parse(end);

    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      dates.add(DateFormat('dd-MM-yyyy').format(date));
    }

    return dates;
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
