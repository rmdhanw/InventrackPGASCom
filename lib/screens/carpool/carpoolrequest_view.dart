import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/auth/auth_bloc.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/routes/router_name.dart';

class CarpoolViewRequest extends StatefulWidget {
  const CarpoolViewRequest({super.key});

  @override
  State<CarpoolViewRequest> createState() => _CarpoolViewRequestState();
}

class _CarpoolViewRequestState extends State<CarpoolViewRequest>
    with SingleTickerProviderStateMixin {
  // Ubah dari single date ke date range
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  late AnimationController _animController;

  // List untuk menyimpan data carpool dari rentang tanggal
  List<Carpool> _carpoolData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();

    // Load data awal
    _loadCarpoolData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Method untuk memuat data carpool berdasarkan rentang tanggal
  Future<void> _loadCarpoolData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDateFormatted = DateFormat('dd-MM-yyyy').format(_startDate);
      final endDateFormatted = DateFormat('dd-MM-yyyy').format(_endDate);

      // Menggunakan method getCarpoolRequestInDateRange yang perlu ditambahkan ke CarpoolBloc
      final carpoolList = await _getCarpoolRequestInDateRange(
          startDateFormatted, endDateFormatted);

      setState(() {
        _carpoolData = carpoolList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  // Method untuk mendapatkan carpool request dalam rentang tanggal
  Future<List<Carpool>> _getCarpoolRequestInDateRange(
      String startDate, String endDate) async {
    List<Carpool> allCarpoolRequests = [];

    DateTime start = DateFormat('dd-MM-yyyy').parse(startDate);
    DateTime end = DateFormat('dd-MM-yyyy').parse(endDate);

    for (DateTime date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(date);

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection("carpool")
            .doc(formattedDate)
            .collection("carpoolRequest")
            .orderBy("createdAt", descending: true)
            .withConverter<Carpool>(
              fromFirestore: (snapshot, _) =>
                  Carpool.fromJson(snapshot.data()!),
              toFirestore: (carpool, _) => carpool.toJson(),
            )
            .get();

        if (snapshot.docs.isNotEmpty) {
          allCarpoolRequests
              .addAll(snapshot.docs.map((e) => e.data()).toList());
        }
      } catch (e) {
        debugPrint(
            'Error loading carpool requests for date $formattedDate: $e');
      }
    }

    return allCarpoolRequests;
  }

  // Method untuk memilih tanggal mulai
  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        // Jika tanggal mulai lebih besar dari tanggal akhir, set tanggal akhir sama dengan tanggal mulai
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
      _loadCarpoolData();
    }
  }

  // Method untuk memilih tanggal akhir
  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate, // Tanggal akhir tidak boleh sebelum tanggal mulai
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _loadCarpoolData();
    }
  }

  Widget _buildCarpoolCard(Carpool carpool, int index) {
    return AnimatedOpacity(
      opacity: 1,
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: Card(
        color: Colors.blue[100],
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final authState = context.read<AuthBloc>().state;
            bool hasAccess = false;

            if (authState is AuthStateAuthenticated) {
              final role = authState.handle.toLowerCase();
              hasAccess = role != 'user';
            }

            if (hasAccess) {
              context.goNamed(
                Routes.carpoolViewRequestDetail,
                pathParameters: {"id": carpool.id},
                extra: carpool,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Anda tidak memiliki akses ke detail.')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pemohon: ${carpool.namapengguna ?? '-'}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                _infoText("Nama Penumpang", carpool.namaPenumpang),
                _infoText("Tim Request", carpool.satuanKerja),
                _infoText("Jam Berangkat", carpool.jamBerangkat),
                _infoText("Jam Kembali", carpool.jamKembali),
                _infoText("Tanggal Request", carpool.tanggalRequest),
                _infoText("Tujuan", carpool.tujuan),
                _infoText("Keperluan", carpool.keperluan),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        "$label: ${value ?? '-'}",
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  // Widget untuk menampilkan filter rentang tanggal
  Widget _buildDateRangeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter Rentang Tanggal",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickStartDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tanggal Mulai",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd-MM-yyyy').format(_startDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickEndDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tanggal Akhir",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd-MM-yyyy').format(_endDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Total: ${_endDate.difference(_startDate).inDays + 1} hari",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final contentWidth = isTablet ? screenWidth * 0.7 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text("APPROVAL CARPOOL",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Widget filter rentang tanggal
              _buildDateRangeFilter(),

              Expanded(
                child: Center(
                  child: Container(
                    width: contentWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _carpoolData.isEmpty
                            ? const Center(
                                child: Text("Tidak ada data request"))
                            : ListView.builder(
                                itemCount: _carpoolData.length,
                                itemBuilder: (context, index) =>
                                    _buildCarpoolCard(
                                        _carpoolData[index], index),
                              ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
