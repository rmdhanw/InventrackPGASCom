import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/auth/auth_bloc.dart'; // Import AuthBloc
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
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
  final CarpoolBloc _carpoolBloc = CarpoolBloc();
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _selectedDate = DateFormat('dd-MM-yyyy').format(date);
      });
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Container(
                      key: ValueKey(_selectedDate),
                      width: contentWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Tanggal: $_selectedDate",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: contentWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot<Carpool>>(
                      stream: _carpoolBloc
                          .streamCarpoolRequestByDate(_selectedDate),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("Tidak ada data carpool."));
                        }

                        final carpools =
                            snapshot.data!.docs.map((e) => e.data()).toList();

                        return ListView.builder(
                          itemCount: carpools.length,
                          itemBuilder: (context, index) =>
                              _buildCarpoolCard(carpools[index], index),
                        );
                      },
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
