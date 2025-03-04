import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';

class CarpoolForm extends StatefulWidget {
  const CarpoolForm({super.key});

  @override
  CarpoolFormState createState() => CarpoolFormState();
}

class CarpoolFormState extends State<CarpoolForm> {
  final TextEditingController _namaPenggunaController = TextEditingController();
  final TextEditingController _satuanKerjaController = TextEditingController();
  final TextEditingController _tujuanController = TextEditingController();
  final TextEditingController _jamBerangkatController = TextEditingController();
  final TextEditingController _jamKembaliController = TextEditingController();
  final TextEditingController _kendaraanController = TextEditingController();
  final TextEditingController _pengemudiController = TextEditingController();
  final TextEditingController _kmAwalController = TextEditingController();
  final TextEditingController _kmAkhirController = TextEditingController();

  @override
  void dispose() {
    _namaPenggunaController.dispose();
    _satuanKerjaController.dispose();
    _tujuanController.dispose();
    _jamBerangkatController.dispose();
    _jamKembaliController.dispose();
    _kendaraanController.dispose();
    _pengemudiController.dispose();
    _kmAwalController.dispose();
    _kmAkhirController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_namaPenggunaController.text.isEmpty ||
        _satuanKerjaController.text.isEmpty ||
        _tujuanController.text.isEmpty ||
        _jamBerangkatController.text.isEmpty ||
        _jamKembaliController.text.isEmpty ||
        _kendaraanController.text.isEmpty ||
        _pengemudiController.text.isEmpty ||
        _kmAwalController.text.isEmpty ||
        _kmAkhirController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field')),
      );
      return;
    }

    context.read<CarpoolBloc>().add(CarpoolEventAdd(
          namaPengguna: _namaPenggunaController.text,
          satuanKerja: _satuanKerjaController.text,
          tujuan: _tujuanController.text,
          jamBerangkat: _jamBerangkatController.text,
          jamKembali: _jamKembaliController.text,
          kendaraan: _kendaraanController.text,
          pengemudi: _pengemudiController.text,
          kmAwal: _kmAwalController.text,
          kmAkhir: _kmAkhirController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'CARPOOL FORM',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.blue,
      body: BlocListener<CarpoolBloc, CarpoolState>(
        listener: (context, state) {
          if (state is CarpoolStateCompleteAdd) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Data berhasil ditambahkan ke Firestore')),
            );
            Navigator.pop(context);
          } else if (state is CarpoolStateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTextField(
                              'Nama Pengguna', _namaPenggunaController),
                          buildTextField(
                              'Satuan Kerja', _satuanKerjaController),
                          buildTextField('Tujuan', _tujuanController),
                          buildTextField(
                              'Jam Berangkat', _jamBerangkatController),
                          buildTextField('Jam Kembali', _jamKembaliController),
                          buildTextField(
                              'Kendaraan / No. Polisi', _kendaraanController),
                          buildTextField('Pengemudi', _pengemudiController),
                          buildTextField('KM Awal', _kmAwalController),
                          buildTextField('KM Akhir', _kmAkhirController),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                      Colors.blue[100])),
                              onPressed: _submitForm,
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.blue[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
