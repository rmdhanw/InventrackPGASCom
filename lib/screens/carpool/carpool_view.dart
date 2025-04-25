import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/routes/router_name.dart';

class CarpoolView extends StatefulWidget {
  const CarpoolView({super.key});

  @override
  State<CarpoolView> createState() => _CarpoolViewState();
}

class _CarpoolViewState extends State<CarpoolView> {
  CarpoolBloc carpool = CarpoolBloc();
  String selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String? selectedDriver;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daftar Carpool",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Date picker
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = DateFormat('dd-MM-yyyy').format(date);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("Tanggal: $selectedDate"),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter by driver
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: carpool.getDriversByDate(selectedDate),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      List<String> drivers = snapshot.data!.docs
                          .map((doc) => doc['pengemudi'] as String)
                          .toSet()
                          .toList();
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        hint: const Text("Pilih Pengemudi"),
                        value: selectedDriver,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text("Semua")),
                          ...drivers.map((driver) => DropdownMenuItem(
                                value: driver,
                                child: Text(driver),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => selectedDriver = value);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Carpool>>(
              stream: carpool.streamCarpoolByDate(selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Tidak ada data carpool."));
                }

                List<Carpool> allCarpool = snapshot.data!.docs
                    .map((e) => e.data())
                    .where((item) =>
                        selectedDriver == null ||
                        item.pengemudi == selectedDriver)
                    .toList();

                if (allCarpool.isEmpty) {
                  return const Center(
                      child: Text("Tidak ada carpool sesuai filter."));
                }

                return ListView.builder(
                  itemCount: allCarpool.length,
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    Carpool carpool = allCarpool[index];
                    return Card(
                      color: Colors.amber,
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => context.goNamed(
                          Routes.carpoolDetail,
                          pathParameters: {"id": carpool.id},
                          extra: carpool,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pengemudi: ${carpool.pengemudi ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Pengguna: ${carpool.namapengguna ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tujuan: ${carpool.tujuan ?? '-'}",
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
