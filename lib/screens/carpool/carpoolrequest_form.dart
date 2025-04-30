import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
import 'package:inventrack/widgets/logo_pgascom.dart';

class RequestCarpool extends StatefulWidget {
  const RequestCarpool({super.key});

  @override
  State<RequestCarpool> createState() => RequestCarpoolState();
}

class RequestCarpoolState extends State<RequestCarpool> {
  final _formKey = GlobalKey<FormState>();

  final namaPenggunaController = TextEditingController();
  final tujuanController = TextEditingController();
  final jamBerangkatController = TextEditingController();
  final jamKembaliController = TextEditingController();
  final _satkerOptions = ["PGNCom", "GasNet"];

  String? _selectedSatker;

  @override
  void dispose() {
    namaPenggunaController.dispose();
    tujuanController.dispose();
    jamBerangkatController.dispose();
    jamKembaliController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CarpoolBloc>().add(CarpoolEventAddRequest(
          namaPengguna: namaPenggunaController.text,
          satuanKerja: _selectedSatker ?? '',
          tujuan: tujuanController.text,
          jamBerangkat: jamBerangkatController.text,
          jamKembali: jamKembaliController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CARPOOL REQUEST',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.blue,
      body: BlocListener<CarpoolBloc, CarpoolState>(
        listener: (context, state) {
          if (state is CarpoolStateCompleteAdd) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data berhasil tersimpan')));
            Navigator.pop(context);
          } else if (state is CarpoolStateError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  const CompanyLogo(),
                  const SizedBox(height: 10),
                  _buildTextField('Nama Pengguna', namaPenggunaController),
                  _buildDropdown(
                      'Satuan Kerja',
                      _satkerOptions,
                      _selectedSatker,
                      (val) => setState(() => _selectedSatker = val)),
                  _buildTextField('Tujuan', tujuanController),
                  _buildTextField('Jam Berangkat', jamBerangkatController),
                  _buildTextField('Jam Kembali', jamKembaliController),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _submitForm,
                    child: const Text('Submit',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: selectedValue,
        items: items
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Pilih $label' : null,
      ),
    );
  }
}
