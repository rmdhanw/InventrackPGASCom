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

  // Variables to store selected times for validation
  TimeOfDay? _selectedDepartureTime;
  TimeOfDay? _selectedReturnTime;

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
      BuildContext context, TextEditingController controller,
      {bool isDeparture = false}) async {
    TimeOfDay initialTime = TimeOfDay.now();

    // Jika memilih jam kembali dan jam berangkat sudah dipilih, gunakan jam berangkat + 1 sebagai saran
    if (!isDeparture && _selectedDepartureTime != null) {
      final suggestedHour = (_selectedDepartureTime!.hour + 1) % 24;
      initialTime = TimeOfDay(
          hour: suggestedHour, minute: _selectedDepartureTime!.minute);
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (!context.mounted) return; // Hindari penggunaan context yang tidak valid

    if (picked != null) {
      // Validasi jam kembali tidak boleh lebih awal dari jam berangkat
      if (!isDeparture && _selectedDepartureTime != null) {
        final departureMinutes =
            _selectedDepartureTime!.hour * 60 + _selectedDepartureTime!.minute;
        final returnMinutes = picked.hour * 60 + picked.minute;

        if (returnMinutes <= departureMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jam kembali harus lebih dari jam berangkat'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      if (!mounted) {
        return; // Pastikan widget masih ada sebelum memanggil setState
      }
      setState(() {
        controller.text = formattedTime;

        if (isDeparture) {
          _selectedDepartureTime = picked;

          // Jika jam kembali sudah diisi tapi jam berangkat baru melebihi jam kembali, kosongkan jam kembali
          if (_selectedReturnTime != null) {
            final newDepartureMinutes = picked.hour * 60 + picked.minute;
            final currentReturnMinutes =
                _selectedReturnTime!.hour * 60 + _selectedReturnTime!.minute;

            if (newDepartureMinutes >= currentReturnMinutes) {
              jamKembaliController.clear();
              _selectedReturnTime = null;
            }
          }
        } else {
          _selectedReturnTime = picked;
        }
      });
    }
  }

  String? _validateReturnTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tidak boleh kosong';
    }

    if (_selectedDepartureTime != null) {
      try {
        final returnTimeParts = value.split(':');
        final returnHour = int.parse(returnTimeParts[0]);
        final returnMinute = int.parse(returnTimeParts[1]);

        final departureMinutes =
            _selectedDepartureTime!.hour * 60 + _selectedDepartureTime!.minute;
        final returnMinutes = returnHour * 60 + returnMinute;

        if (returnMinutes <= departureMinutes) {
          return 'Jam kembali harus lebih dari jam berangkat';
        }
      } catch (e) {
        return 'Format waktu tidak valid';
      }
    }

    return null;
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
                    onTap: () => _selectTime24H(context, jamBerangkatController,
                        isDeparture: true),
                  ),
                  _buildTextFieldWithCustomValidator(
                    'Jam Kembali',
                    jamKembaliController,
                    validator: _validateReturnTime,
                    onTap: () => _selectTime24H(context, jamKembaliController,
                        isDeparture: false),
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
                  // Updated Submit Button with BlocBuilder and Loading Indicator
                  BlocBuilder<CarpoolBloc, CarpoolState>(
                    builder: (context, state) {
                      final isLoading = state is CarpoolStateLoadingAdd;

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: isLoading ? null : _submitForm,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      );
                    },
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

  Widget _buildTextFieldWithCustomValidator(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    VoidCallback? onTap,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: onTap != null || readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: validator ??
            ((value) =>
                (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null),
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
        initialValue: selectedValue,
        items: items
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Pilih $label' : null,
      ),
    );
  }
}
