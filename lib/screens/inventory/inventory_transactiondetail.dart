import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/inventory/inventory_bloc.dart';
import 'package:inventrack/models/inventory.dart';

class InventoryTransactionDetail extends StatefulWidget {
  final String id;
  final Inventory inventory;

  const InventoryTransactionDetail(
    this.id,
    this.inventory, {
    super.key,
  });

  @override
  State<InventoryTransactionDetail> createState() =>
      _InventoryTransactionDetailState();
}

class _InventoryTransactionDetailState
    extends State<InventoryTransactionDetail> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController namaBarangController;
  late TextEditingController nomorSerialController;
  late TextEditingController keteranganController;

  String? _selectedKategori;
  String? _selectedKondisi;
  String? _selectedStatus;

  List<String> _categories = [];
  final List<String> _kondisiOptions = ['Baik', 'Underperform', 'Buruk'];
  final List<String> _statusOptions = ['Masuk', 'Keluar'];

  bool _showCustomKategoriField = false;
  late TextEditingController customKategoriController;

  @override
  void initState() {
    super.initState();
    final inventory = widget.inventory;

    namaBarangController = TextEditingController(text: inventory.namaBarang);
    nomorSerialController = TextEditingController(text: inventory.nomorSerial);
    keteranganController = TextEditingController(text: inventory.keterangan);

    _selectedKategori = inventory.kategori;
    _selectedKondisi = inventory.kondisi;
    _selectedStatus = inventory.status;

    customKategoriController = TextEditingController();

    context.read<InventoryBloc>().add(LoadCategories());
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

    final kategori = _showCustomKategoriField
        ? customKategoriController.text.trim()
        : _selectedKategori ?? '';

    context.read<InventoryBloc>().add(InventoryEventEditTransaction(
          id: widget.id,
          namaBarang: namaBarangController.text,
          nomorSerial: nomorSerialController.text,
          kategori: kategori,
          kondisi: _selectedKondisi ?? '',
          status: _selectedStatus ?? '',
          keterangan: keteranganController.text,
          tanggal: widget.inventory.tanggal ?? '',
        ));
  }

  void _deleteData() {
    context
        .read<InventoryBloc>()
        .add(InventoryEventDeleteTransaction(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryStateCompleteEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data berhasil diperbarui')));
          Navigator.pop(context);
        } else if (state is InventorySuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.pop(context);
        } else if (state is InventoryError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Detail Transaksi Inventory",
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
                  child: BlocBuilder<InventoryBloc, InventoryState>(
                    builder: (context, state) {
                      if (state is InventoryLoaded ||
                          state is CategoriesLoaded) {
                        if (state is InventoryLoaded) {
                          _categories = state.categories;
                        } else if (state is CategoriesLoaded) {
                          _categories = (state).categories;
                        }
                      }

                      return ListView(
                        children: [
                          _buildInfoField('Nama Barang',
                              widget.inventory.namaBarang ?? '-'),
                          _buildInfoField('Nomor Serial',
                              widget.inventory.nomorSerial ?? '-'),
                          _buildDropdownKategori(
                            label: 'Kategori Barang',
                            items: _categories,
                          ),
                          if (_showCustomKategoriField)
                            _buildTextField(
                                'Kategori Lainnya', customKategoriController),
                          _buildDropdown(
                            label: 'Kondisi',
                            value: _selectedKondisi,
                            items: _kondisiOptions,
                            onChanged: (value) {
                              setState(() {
                                _selectedKondisi = value;
                              });
                            },
                          ),
                          _buildDropdown(
                            label: 'Status',
                            value: _selectedStatus,
                            items: _statusOptions,
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                          ),
                          _buildTextField('Keterangan', keteranganController),
                          _buildInfoField(
                              'Tanggal', widget.inventory.tanggal ?? '-'),
                        ],
                      );
                    },
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

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
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

  Widget _buildDropdownKategori({
    required String label,
    required List<String> items,
  }) {
    final extendedItems = [...items, 'Lainnya'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        initialValue: extendedItems.contains(_selectedKategori)
            ? _selectedKategori
            : null,
        items: extendedItems.isEmpty
            ? [const DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya'))]
            : extendedItems
                .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                .toList(),
        onChanged: (value) {
          setState(() {
            _selectedKategori = value;
            _showCustomKategoriField = value == 'Lainnya';
          });
        },
        validator: (value) => value == null ? 'Pilih $label' : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        initialValue: items.contains(value) ? value : null,
        items: items
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Pilih $label' : null,
      ),
    );
  }
}
