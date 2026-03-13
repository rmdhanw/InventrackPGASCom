import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/routes/router_name.dart';
import 'package:table_calendar/table_calendar.dart';

class CarpoolView extends StatefulWidget {
  const CarpoolView({super.key});

  @override
  State<CarpoolView> createState() => _CarpoolViewState();
}

class _CarpoolViewState extends State<CarpoolView> {
  CarpoolBloc carpool = CarpoolBloc();

  DateTime firstDay = DateTime.now().subtract(const Duration(days: 365));
  DateTime lastDay = DateTime.now().add(const Duration(days: 365));
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  CalendarFormat calendarFormat = CalendarFormat.month;
  String? selectedDriver;
  Map<DateTime, List<Carpool>> carpoolEvents = {};
  List<Carpool> selectedEvents = [];

  // Cache untuk menyimpan data yang sudah di-load
  Map<String, Map<DateTime, List<Carpool>>> monthlyCache = {};

  bool isLoading = true;
  bool isCalendarView = true;

  @override
  void initState() {
    super.initState();
    selectedDay = focusedDay;
    _loadCarpoolDataForMonth();
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

  String _getMonthKey(DateTime date) {
    return "${date.year}-${date.month}";
  }

  Future<void> _loadCarpoolDataForMonth() async {
    String monthKey = _getMonthKey(focusedDay);

    // Cek cache terlebih dahulu
    if (monthlyCache.containsKey(monthKey)) {
      setState(() {
        carpoolEvents = monthlyCache[monthKey]!;
        isLoading = false;
      });

      if (selectedDay != null) {
        _updateSelectedEvents(selectedDay!);
      }
      return;
    }

    setState(() {
      isLoading = true;
      carpoolEvents = {};
    });

    try {
      // OPTIMASI 1: Query dengan rentang tanggal yang lebih efisien
      await _loadCarpoolDataOptimized();

      // Simpan ke cache
      monthlyCache[monthKey] = Map.from(carpoolEvents);
    } catch (e) {
      debugPrint('Error loading carpool data: $e');
    }

    if (selectedDay != null) {
      _updateSelectedEvents(selectedDay!);
    }

    setState(() {
      isLoading = false;
    });
  }

  // OPTIMASI 1: Gunakan query yang lebih efisien
  Future<void> _loadCarpoolDataOptimized() async {
    DateTime firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    DateTime lastDayOfMonth =
        DateTime(focusedDay.year, focusedDay.month + 1, 0);

    // OPTIMASI 2: Batasi query hanya untuk hari-hari yang mungkin ada data
    List<String> dateRange = _getDateRange(
        _formatDate(firstDayOfMonth), _formatDate(lastDayOfMonth));

    // OPTIMASI 3: Query paralel dengan batching
    List<Future<void>> queryFutures = [];

    // Bagi query menjadi batch untuk menghindari terlalu banyak concurrent request
    const int batchSize = 5;

    for (int i = 0; i < dateRange.length; i += batchSize) {
      int end =
          (i + batchSize < dateRange.length) ? i + batchSize : dateRange.length;
      List<String> batch = dateRange.sublist(i, end);

      queryFutures.add(_loadBatchData(batch));
    }

    await Future.wait(queryFutures);
  }

  Future<void> _loadBatchData(List<String> dates) async {
    List<Future<void>> batchFutures =
        dates.map((date) => _loadSingleDateData(date)).toList();
    await Future.wait(batchFutures);
  }

  Future<void> _loadSingleDateData(String date) async {
    try {
      QuerySnapshot<Carpool> snapshot = await FirebaseFirestore.instance
          .collection("carpool")
          .doc(date)
          .collection("carpoolItems")
          .orderBy("createdAt", descending: true)
          .limit(50) // OPTIMASI 4: Batasi jumlah dokumen yang diambil
          .withConverter<Carpool>(
            fromFirestore: (snapshot, _) => Carpool.fromJson(snapshot.data()!),
            toFirestore: (carpool, _) => carpool.toJson(),
          )
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<Carpool> carpools = snapshot.docs.map((e) => e.data()).toList();
        DateTime dateKey = _parseDate(date);

        // Gunakan synchronized update untuk menghindari race condition
        if (mounted) {
          setState(() {
            carpoolEvents[DateTime(dateKey.year, dateKey.month, dateKey.day)] =
                carpools;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data for date $date: $e');
    }
  }

  List<String> _getDateRange(String start, String end) {
    List<String> dates = [];
    DateTime startDate = _parseDate(start);
    DateTime endDate = _parseDate(end);

    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      dates.add(DateFormat('dd-MM-yyyy').format(date));
    }

    return dates;
  }

  List<Carpool> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    List<Carpool> events = carpoolEvents[normalizedDay] ?? [];

    if (selectedDriver != null && selectedDriver != "Semua") {
      return events
          .where((event) => event.pengemudi == selectedDriver)
          .toList();
    }

    return events;
  }

  void _updateSelectedEvents(DateTime day) {
    setState(() {
      selectedDay = day;
      selectedEvents = _getEventsForDay(day);
    });
  }

  // OPTIMASI 5: Cache unique drivers
  List<String>? _cachedDrivers;
  List<String> _getUniqueDrivers() {
    if (_cachedDrivers != null) return _cachedDrivers!;

    Set<String> drivers = {"Semua"};
    carpoolEvents.forEach((date, carpools) {
      for (var carpool in carpools) {
        if (carpool.pengemudi != null && carpool.pengemudi!.isNotEmpty) {
          drivers.add(carpool.pengemudi!);
        }
      }
    });

    _cachedDrivers = drivers.toList();
    return _cachedDrivers!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CARPOOL SERVICES",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(isCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () {
              setState(() {
                isCalendarView = !isCalendarView;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // OPTIMASI 6: Lazy loading untuk dropdown
          _buildDriverDropdown(),

          if (isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Memuat data carpool..."),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: isCalendarView ? _buildCalendarView() : _buildListView(),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverDropdown() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              hint: const Text("Pilih Pengemudi"),
              initialValue: selectedDriver,
              items: [
                const DropdownMenuItem(value: "Semua", child: Text("Semua")),
                ..._getUniqueDrivers()
                    .where((item) => item != "Semua")
                    .map((driver) => DropdownMenuItem(
                          value: driver,
                          child: Text(driver),
                        )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedDriver = value;
                  _cachedDrivers = null; // Reset cache ketika filter berubah
                  if (selectedDay != null) {
                    _updateSelectedEvents(selectedDay!);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: focusedDay,
          calendarFormat: calendarFormat,
          eventLoader: _getEventsForDay,
          selectedDayPredicate: (day) {
            return isSameDay(selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            _updateSelectedEvents(selectedDay);
            setState(() {
              this.selectedDay = selectedDay;
              this.focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              this.focusedDay = focusedDay;
              _cachedDrivers = null; // Reset cache ketika pindah bulan
            });
            _loadCarpoolDataForMonth();
          },
          calendarStyle: const CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Text(
                      events.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: selectedEvents.isEmpty
              ? const Center(child: Text("Tidak ada carpool pada tanggal ini"))
              : ListView.builder(
                  itemCount: selectedEvents.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    Carpool carpoolItem = selectedEvents[index];
                    return _buildCarpoolCard(carpoolItem);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    List<Carpool> allCarpoolData = [];
    carpoolEvents.forEach((date, events) {
      if (selectedDriver == null || selectedDriver == "Semua") {
        allCarpoolData.addAll(events);
      } else {
        allCarpoolData.addAll(
            events.where((item) => item.pengemudi == selectedDriver).toList());
      }
    });

    allCarpoolData.sort((a, b) {
      DateTime dateA = _parseDate(a.formattedDate);
      DateTime dateB = _parseDate(b.formattedDate);
      return dateB.compareTo(dateA);
    });

    return allCarpoolData.isEmpty
        ? const Center(child: Text("Tidak ada carpool sesuai filter."))
        : ListView.builder(
            itemCount: allCarpoolData.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              return _buildCarpoolCard(allCarpoolData[index]);
            },
          );
  }

  Widget _buildCarpoolCard(Carpool carpoolItem) {
    return Card(
      color: Colors.blue[100],
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          final authState = context.read<AuthBloc>().state;
          bool hasAccess = false;

          if (authState is AuthStateAuthenticated) {
            final role = authState.handle.toLowerCase();
            hasAccess = role != 'user';
          }

          if (hasAccess) {
            context.goNamed(
              Routes.carpoolDetail,
              pathParameters: {"id": carpoolItem.id},
              extra: carpoolItem,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Anda tidak memiliki akses ke detail.')),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pengemudi: ${carpoolItem.pengemudi ?? '-'}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tanggal: ${carpoolItem.formattedDate}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Penumpang: ${carpoolItem.namaPenumpang ?? '-'}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tujuan: ${carpoolItem.tujuan ?? '-'}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Keperluan: ${carpoolItem.keperluan ?? '-'}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Status Driver: ${carpoolItem.statusDriver ?? '-'}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Bersihkan cache jika perlu
    monthlyCache.clear();
    super.dispose();
  }
}
