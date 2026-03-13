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

  // Variables to store selected times for validation
  TimeOfDay? _selectedDepartureTime;
  TimeOfDay? _selectedReturnTime;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
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

    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final rolesList = [
        'Engineer',
        'Driver',
        'Manager RO',
        'Office',
        'Security'
      ];

      String? userName;

      for (final role in rolesList) {
        final doc = await FirebaseFirestore.instance
            .collection('roles')
            .doc(role)
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists && doc.data()?['name'] != null) {
          userName = doc.data()?['name'];
          debugPrint('User ditemukan di role: $role');
          break;
        }
      }

      if (mounted && userName != null) {
        setState(() {
          namaPenggunaController.text = userName!;
        });
      } else {
        debugPrint('Pengguna tidak ditemukan di semua role');
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

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now, // Only today and future dates
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        final formattedDate =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
        tanggalRequestController.text = formattedDate;
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
                                  context, jamBerangkatController,
                                  isDeparture: true),
                            ),
                            _buildTextFieldWithCustomValidator(
                              'Jam Kembali',
                              jamKembaliController,
                              validator: _validateReturnTime,
                              onTap: () => _selectTime24H(
                                  context, jamKembaliController,
                                  isDeparture: false),
                            ),
                            _buildTextField(
                              'Tanggal Request',
                              tanggalRequestController,
                              onTap: () => _selectDate(context),
                            ),
                            const SizedBox(height: 20),
                            BlocBuilder<CarpoolBloc, CarpoolState>(
                              builder: (context, state) {
                                final isLoading =
                                    state is CarpoolStateLoadingAdd;

                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[100],
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                  ),
                                  onPressed: isLoading ? null : _submitForm,
                                  child: isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth:
                                                constraints.maxWidth < 360
                                                    ? 1.5
                                                    : 2,
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
