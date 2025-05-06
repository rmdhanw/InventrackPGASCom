import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
import 'package:inventrack/widgets/logo_pgascom.dart';

class RequestCarpool extends StatefulWidget {
  const RequestCarpool({super.key});

  @override
  State<RequestCarpool> createState() => RequestCarpoolState();
}

class RequestCarpoolState extends State<RequestCarpool>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final namaPenggunaController = TextEditingController();
  final namaPenumpangController = TextEditingController();
  final tujuanController = TextEditingController();
  final keperluanController = TextEditingController();
  final jamBerangkatController = TextEditingController();
  final jamKembaliController = TextEditingController();
  final tanggalRequestController = TextEditingController();

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

  String? _selectedSatker;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    tanggalRequestController.text =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // Load user name from Firestore
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('roles')
          .doc('Engineer')
          .collection('users')
          .doc(uid)
          .get();

      final name = doc.data()?['name'];
      if (name != null) {
        setState(() {
          namaPenggunaController.text = name;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat nama pengguna: $e');
    }
  }

  @override
  void dispose() {
    namaPenggunaController.dispose();
    namaPenumpangController.dispose();
    tujuanController.dispose();
    keperluanController.dispose();
    jamBerangkatController.dispose();
    jamKembaliController.dispose();
    tanggalRequestController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CarpoolBloc>().add(CarpoolEventAddRequest(
          namaPengguna: namaPenggunaController.text,
          namaPenumpang: namaPenumpangController.text,
          satuanKerja: _selectedSatker ?? '',
          tujuan: tujuanController.text,
          keperluan: keperluanController.text,
          jamBerangkat: jamBerangkatController.text,
          jamKembali: jamKembaliController.text,
          tanggalRequest: tanggalRequestController.text,
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

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      tanggalRequestController.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('REQUEST USER',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              final contentWidth = isTablet ? width * 0.6 : width;

              return SingleChildScrollView(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: const EdgeInsets.all(25),
                    width: contentWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const CompanyLogo(),
                            const SizedBox(height: 10),
                            _buildTextField(
                              'Nama Pemohon',
                              namaPenggunaController,
                              readOnly: true,
                            ),
                            _buildTextField(
                              'Nama Penumpang',
                              namaPenumpangController,
                            ),
                            _buildDropdown(
                              'Tim Request',
                              _satkerOptions,
                              _selectedSatker,
                              (val) => setState(() => _selectedSatker = val),
                            ),
                            _buildTextField('Tujuan', tujuanController),
                            _buildTextField('Keperluan', keperluanController),
                            _buildTextField(
                              'Jam Berangkat',
                              jamBerangkatController,
                              onTap: () => _selectTime24H(
                                  context, jamBerangkatController),
                            ),
                            _buildTextField(
                              'Jam Kembali',
                              jamKembaliController,
                              onTap: () =>
                                  _selectTime24H(context, jamKembaliController),
                            ),
                            _buildTextField(
                              'Tanggal Request',
                              tanggalRequestController,
                              onTap: () => _selectDate(context),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[100],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              onPressed: _submitForm,
                              child: const Text('Submit',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                          ],
                        ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: onTap != null || readOnly,
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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
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
