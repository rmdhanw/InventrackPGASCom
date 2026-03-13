import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/carpool/carpool_bloc.dart';
import 'package:inventrack/models/carpool.dart';

class CarpoolDetail extends StatefulWidget {
  final String id;
  final Carpool carpool;

  const CarpoolDetail(
    this.id,
    this.carpool, {
    super.key,
  });

  @override
  State<CarpoolDetail> createState() => _CarpoolDetailState();
}

class _CarpoolDetailState extends State<CarpoolDetail> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController namaPenggunaController;
  late TextEditingController namaPenumpangController;
  late TextEditingController tujuanController;
  late TextEditingController keperluanController;
  late TextEditingController jamBerangkatController;
  late TextEditingController jamKembaliController;
  late TextEditingController kendaraanController;
  late TextEditingController kmAwalController;
  late TextEditingController kmAkhirController;

  String? _selectedSatker;
  String? _selectedDriver;
  String? _selectedStatusDriver;

  @override
  void initState() {
    super.initState();
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
    _selectedSatker = carpool.satuanKerja;
    _selectedDriver = carpool.pengemudi;
    _selectedStatusDriver = carpool.statusDriver;
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
                _updateData();
                Navigator.pop(ctx);
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
        content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
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

  void _updateData() {
    if (!_formKey.currentState!.validate()) return;

    String formattedDate = widget.carpool.formattedDate;
    if (formattedDate.isEmpty) {
      final now = DateTime.now();
      formattedDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    }
    _selectedDriver ??= widget.carpool.pengemudi;

    context.read<CarpoolBloc>().add(CarpoolEventEditCarpool(
          id: widget.id,
          namaPengguna: namaPenggunaController.text,
          namaPenumpang: namaPenumpangController.text,
          satuanKerja: _selectedSatker!,
          tujuan: tujuanController.text,
          keperluan: keperluanController.text,
          jamBerangkat: jamBerangkatController.text,
          jamKembali: jamKembaliController.text,
          kendaraan: kendaraanController.text,
          pengemudi: _selectedDriver!,
          kmAwal: kmAwalController.text,
          kmAkhir: kmAkhirController.text,
          statusDriver: _selectedStatusDriver!,
          formattedDate: widget.carpool.formattedDate,
        ));
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
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  void _deleteData() {
    context.read<CarpoolBloc>().add(CarpoolEventDelete(widget.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text("Detail Carpool",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
        ),
        body: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _buildTextField('Nama Pengguna', namaPenggunaController),
                      _buildTextField(
                          'Nama Penumpang', namaPenumpangController),
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
                        onTap: () =>
                            _selectTime24H(context, jamKembaliController),
                      ),
                      _buildTextField('No. Polisi', kendaraanController),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: TextFormField(
                          initialValue: _selectedDriver,
                          readOnly: true,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Pengemudi (tidak dapat diubah)',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      _buildTextField('KM Awal', kmAwalController,
                          isNumber: true),
                      _buildTextField('KM Akhir', kmAkhirController,
                          isNumber: true),
                      _buildDropdown(
                          'Status Driver',
                          ['Bertugas', 'Stand by', 'Cuti'],
                          _selectedStatusDriver,
                          (val) => setState(() => _selectedStatusDriver = val)),
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
                        child: const Text("Simpan Perubahan",
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
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
