import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
import 'package:inventrack/models/carpool.dart';

class CarpoolRequestDetail extends StatefulWidget {
  final String id;
  final Carpool carpool;

  const CarpoolRequestDetail(this.id, this.carpool, {super.key});

  @override
  State<CarpoolRequestDetail> createState() => _CarpoolDetailState();
}

class _CarpoolDetailState extends State<CarpoolRequestDetail>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late TextEditingController namaPenggunaController;
  late TextEditingController tujuanController;
  late TextEditingController keperluanController;
  late TextEditingController jamBerangkatController;
  late TextEditingController jamKembaliController;
  late TextEditingController kendaraanController;
  late TextEditingController kmAwalController;
  late TextEditingController kmAkhirController;
  late TextEditingController tanggalRequestController;
  late TextEditingController namaPenumpangController;

  String? _selectedSatker;
  String? _selectedDriver;
  String? _selectedStatusDriver;
  List<String> _driverOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    final carpool = widget.carpool;
    namaPenggunaController = TextEditingController(text: carpool.namapengguna);
    namaPenumpangController =
        TextEditingController(text: carpool.namaPenumpang);
    tujuanController = TextEditingController(text: carpool.tujuan);
    keperluanController = TextEditingController(text: carpool.keperluan);
    jamBerangkatController = TextEditingController(text: carpool.jamBerangkat);
    jamKembaliController = TextEditingController(text: carpool.jamKembali);
    kendaraanController = TextEditingController(text: carpool.kendaraan);
    kmAwalController = TextEditingController(text: carpool.kmAwal);
    kmAkhirController = TextEditingController(text: carpool.kmAkhir);
    tanggalRequestController =
        TextEditingController(text: carpool.tanggalRequest);
    _selectedSatker = carpool.satuanKerja ?? '-';
    _selectedStatusDriver = carpool.statusDriver ?? '-';
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("roles")
          .doc("Driver")
          .collection("users")
          .get();

      final drivers = snapshot.docs
          .map((doc) => doc.data()["name"] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .map((name) => name!)
          .toSet()
          .toList();

      setState(() {
        _driverOptions = ['-', ...drivers];
        _selectedDriver = (widget.carpool.pengemudi != null &&
                drivers.contains(widget.carpool.pengemudi))
            ? widget.carpool.pengemudi
            : '-';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Gagal memuat driver: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return BlocListener<CarpoolBloc, CarpoolState>(
      listener: (context, state) {
        if (state is CarpoolStateCompleteEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data berhasil diperbarui')));
          Navigator.pop(context);
        } else if (state is CarpoolStateError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Detail Request Carpool",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: isLargeScreen ? 600 : double.infinity),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView(
                                children: [
                                  _buildTextField(
                                      'Nama Pengguna', namaPenggunaController),
                                  _buildTextField('Nama Penumpang',
                                      namaPenumpangController),
                                  _buildDropdown(
                                      'Tim Request',
                                      [
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
                                      ],
                                      _selectedSatker,
                                      (val) => setState(
                                          () => _selectedSatker = val)),
                                  _buildTextField('Tujuan', tujuanController),
                                  _buildTextField(
                                      'Keperluan', keperluanController),
                                  _buildTextField(
                                      'Jam Berangkat', jamBerangkatController,
                                      onTap: () => _selectTime24H(
                                          context, jamBerangkatController)),
                                  _buildTextField(
                                      'Jam Kembali', jamKembaliController,
                                      onTap: () => _selectTime24H(
                                          context, jamKembaliController)),
                                  _buildTextField('Tanggal Request',
                                      tanggalRequestController,
                                      onTap: () => _selectDate(context)),
                                  _buildTextField(
                                      'No. Polisi', kendaraanController),
                                  _buildDropdown(
                                      'Pengemudi',
                                      _driverOptions,
                                      _selectedDriver,
                                      (val) => setState(
                                          () => _selectedDriver = val)),
                                  _buildTextField('KM Awal', kmAwalController,
                                      isNumber: true),
                                  _buildDropdown(
                                      'Status Driver',
                                      ['Bertugas', 'Stand by', 'Cuti'],
                                      _selectedStatusDriver,
                                      (val) => setState(
                                          () => _selectedStatusDriver = val)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _confirmUpdate,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[100]),
                                    child: const Text("Konfirmasi",
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _confirmDelete,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[100]),
                                    child: const Text("Hapus Data",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
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
    final displayItems = ['-', ...items.toSet().where((e) => e != '-')];
    final displayValue =
        (selectedValue == null || !displayItems.contains(selectedValue))
            ? '-'
            : selectedValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: displayValue,
        validator: (value) =>
            value == null || value.isEmpty ? 'Tidak boleh kosong' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: displayItems
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _confirmUpdate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin menyimpan perubahan?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateData();
              },
              child: const Text("Ya")),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin menolak?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteData();
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _updateData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection("carpool")
          .doc(widget.carpool.formattedDate)
          .collection("carpoolRequest")
          .doc(widget.id);

      final docSnapshot = await docRef.get();
      if (!mounted) return;
      if (!docSnapshot.exists) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data tidak ditemukan. Mungkin telah dihapus.'),
              backgroundColor: Colors.red),
        );
        Navigator.pop(context);
        return;
      }

      context.read<CarpoolBloc>().add(CarpoolEventEditCarpoolRequest(
            id: widget.id,
            namaPengguna: namaPenggunaController.text,
            namaPenumpang: namaPenumpangController.text,
            satuanKerja: _selectedSatker ?? '-',
            tujuan: tujuanController.text,
            keperluan: keperluanController.text,
            jamBerangkat: jamBerangkatController.text,
            jamKembali: jamKembaliController.text,
            kendaraan: kendaraanController.text,
            pengemudi: _selectedDriver ?? '-',
            kmAwal: kmAwalController.text,
            kmAkhir: '-',
            statusDriver: _selectedStatusDriver ?? '-',
            formattedDate: widget.carpool.formattedDate,
            tanggalRequest: tanggalRequestController.text,
          ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _deleteData() {
    context.read<CarpoolBloc>().add(
        CarpoolEventDeleteRequest(widget.id, widget.carpool.formattedDate));
    Navigator.pop(context);
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
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
      tanggalRequestController.text =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    }
  }
}
