import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:intl/intl.dart';
import 'package:inventrack/routes/router_name.dart';

class CarpoolViewRequest extends StatefulWidget {
  const CarpoolViewRequest({super.key});

  @override
  State<CarpoolViewRequest> createState() => _CarpoolViewRequestState();
}

class _CarpoolViewRequestState extends State<CarpoolViewRequest> {
  final CarpoolBloc _carpoolBloc = CarpoolBloc();
  String _selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

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

  Widget _buildCarpoolCard(Carpool carpool) {
    return Card(
      color: Colors.blue[100],
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => context.goNamed(
          Routes.carpoolDetail,
          pathParameters: {"id": carpool.id},
          extra: carpool,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                "Pemohon: ${carpool.namapengguna ?? '-'}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Satuan Kerja: ${carpool.satuanKerja ?? '-'}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                "Jam Berangkat: ${carpool.jamBerangkat ?? '-'}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                "Jam Kembali: ${carpool.jamKembali ?? '-'}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                "Tujuan: ${carpool.tujuan ?? '-'}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Carpool Request",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Tanggal: $_selectedDate"),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Carpool>>(
              stream: _carpoolBloc.streamCarpoolRequestByDate(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Tidak ada data carpool."));
                }

                final carpools =
                    snapshot.data!.docs.map((e) => e.data()).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: carpools.length,
                  itemBuilder: (context, index) =>
                      _buildCarpoolCard(carpools[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
