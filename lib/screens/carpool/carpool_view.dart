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

  bool isLoading = true;
  bool isCalendarView = true; // Toggle between calendar and list view

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

  Future<void> _loadCarpoolDataForMonth() async {
    setState(() {
      isLoading = true;
      carpoolEvents = {};
    });

    DateTime firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    DateTime lastDayOfMonth =
        DateTime(focusedDay.year, focusedDay.month + 1, 0);

    String startDateStr = _formatDate(firstDayOfMonth);
    String endDateStr = _formatDate(lastDayOfMonth);

    List<String> dateRange = _getDateRange(startDateStr, endDateStr);

    for (String date in dateRange) {
      try {
        QuerySnapshot<Carpool> snapshot = await FirebaseFirestore.instance
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
          DateTime dateKey = _parseDate(date);

          setState(() {
            carpoolEvents[DateTime(dateKey.year, dateKey.month, dateKey.day)] =
                carpools;
          });
        }
      } catch (e) {
        debugPrint('Error loading data for date $date: $e');
      }
    }

    if (selectedDay != null) {
      _updateSelectedEvents(selectedDay!);
    }

    setState(() {
      isLoading = false;
    });
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
    // Normalize date to avoid time issues
    final normalizedDay = DateTime(day.year, day.month, day.day);

    // Apply driver filter
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

  List<String> _getUniqueDrivers() {
    Set<String> drivers = {"Semua"};

    carpoolEvents.forEach((date, carpools) {
      for (var carpool in carpools) {
        if (carpool.pengemudi != null && carpool.pengemudi!.isNotEmpty) {
          drivers.add(carpool.pengemudi!);
        }
      }
    });

    return drivers.toList();
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
          // Toggle between calendar and list view
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    hint: const Text("Pilih Pengemudi"),
                    value: selectedDriver,
                    items: [
                      const DropdownMenuItem(
                          value: "Semua", child: Text("Semua")),
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
                        if (selectedDay != null) {
                          _updateSelectedEvents(selectedDay!);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: isCalendarView ? _buildCalendarView() : _buildListView(),
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
            });
            // Load data for the new month
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
    // Flatten all events for list view
    List<Carpool> allCarpoolData = [];
    carpoolEvents.forEach((date, events) {
      if (selectedDriver == null || selectedDriver == "Semua") {
        allCarpoolData.addAll(events);
      } else {
        allCarpoolData.addAll(
            events.where((item) => item.pengemudi == selectedDriver).toList());
      }
    });

    // Sort by date
    allCarpoolData.sort((a, b) {
      DateTime dateA = _parseDate(a.formattedDate);
      DateTime dateB = _parseDate(b.formattedDate);
      return dateB.compareTo(dateA); // Descending order
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
}
