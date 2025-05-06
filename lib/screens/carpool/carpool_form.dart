import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
import 'package:inventrack/widgets/logo_pgascom.dart';

class CarpoolForm extends StatefulWidget {
  const CarpoolForm({super.key});

  @override
  State<CarpoolForm> createState() => _CarpoolFormState();
}

class _CarpoolFormState extends State<CarpoolForm> {
  final _formKey = GlobalKey<FormState>();

  final namaPenumpangController = TextEditingController();
  final tujuanController = TextEditingController();
  final keperluanController = TextEditingController();
  final jamBerangkatController = TextEditingController();
  final jamKembaliController = TextEditingController();
  final kendaraanController = TextEditingController();
  final kmAwalController = TextEditingController();
  final kmAkhirController = TextEditingController();

  final _satkerOptions = [
    'ICS',
    'Offtake',
    'PMD',
    'LPS',
    'SIRKOM',
    'Komersial',
    'Office',
    'OSM',
    'Project',
    'ICT',
    'Tamu',
    'Lainnya'
  ];
  final _statusDriverOptions = ['Bertugas', 'Stand by', 'Cuti'];
  List<String> _driverOptions = [];

  String? _selectedSatker;
  String? _selectedStatusDriver;
  String? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("roles")
          .doc("Driver")
          .collection("users")
          .get();

      setState(() {
        _driverOptions =
            snapshot.docs.map((doc) => doc.data()["name"] as String).toList();
      });
    } catch (e) {
      debugPrint("Gagal memuat driver: $e");
    }
  }

  @override
  void dispose() {
    namaPenumpangController.dispose();
    tujuanController.dispose();
    keperluanController.dispose();
    jamBerangkatController.dispose();
    jamKembaliController.dispose();
    kendaraanController.dispose();
    kmAwalController.dispose();
    kmAkhirController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CarpoolBloc>().add(CarpoolEventAdd(
          namaPengguna: 'Bypass',
          namaPenumpang: namaPenumpangController.text,
          satuanKerja: _selectedSatker ?? '',
          tujuan: tujuanController.text,
          keperluan: keperluanController.text,
          jamBerangkat: jamBerangkatController.text,
          jamKembali: jamKembaliController.text,
          kendaraan: kendaraanController.text,
          pengemudi: _selectedDriver ?? '',
          kmAwal: kmAwalController.text,
          statusDriver: _selectedStatusDriver ?? '',
        ));
  }

  Future<void> _selectTime24H(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BYPASS CARPOOL',
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
                  _buildTextField('Nama Penumpang', namaPenumpangController),
                  _buildDropdown('Tim Request', _satkerOptions, _selectedSatker,
                      (val) => setState(() => _selectedSatker = val)),
                  _buildTextField('Tujuan', tujuanController),
                  _buildTextField('Keperluan', keperluanController),
                  _buildTextField(
                    'Jam Berangkat',
                    jamBerangkatController,
                    onTap: () =>
                        _selectTime24H(context, jamBerangkatController),
                  ),
                  _buildTextField(
                    'Jam Kembali',
                    jamKembaliController,
                    onTap: () => _selectTime24H(context, jamKembaliController),
                  ),
                  _buildTextField('No. Polisi', kendaraanController),
                  _buildDropdown('Driver', _driverOptions, _selectedDriver,
                      (val) => setState(() => _selectedDriver = val)),
                  _buildTextField('KM Awal', kmAwalController, isNumber: true),
                  _buildDropdown(
                      'Status Driver',
                      _statusDriverOptions,
                      _selectedStatusDriver,
                      (val) => setState(() => _selectedStatusDriver = val)),
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
      {bool isNumber = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: onTap != null,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null,
        onTap: onTap,
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
