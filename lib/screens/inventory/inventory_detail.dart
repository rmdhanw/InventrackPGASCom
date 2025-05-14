import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/inventory/inventory_bloc.dart';
import 'package:inventrack/models/inventory.dart';

class InventoryDetail extends StatefulWidget {
  final String id;
  final Inventory inventory;

  const InventoryDetail(
    this.id,
    this.inventory, {
    super.key,
  });

  @override
  State<InventoryDetail> createState() => _InventoryDetailState();
}

class _InventoryDetailState extends State<InventoryDetail> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController namaBarangController;
  late TextEditingController nomorSerialController;

  String? _selectedKategori;
  List<String> _categories = [];
  bool _showCustomKategoriField = false;
  late TextEditingController customKategoriController;

  @override
  void initState() {
    super.initState();
    final inventory = widget.inventory;
    namaBarangController = TextEditingController(text: inventory.namaBarang);
    nomorSerialController = TextEditingController(text: inventory.nomorSerial);
    _selectedKategori = inventory.kategori;
    customKategoriController = TextEditingController();

    // Load categories when the form is initialized
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

    context.read<InventoryBloc>().add(InventoryEventEditInventory(
          id: widget.id,
          namaBarang: namaBarangController.text,
          nomorSerial: nomorSerialController.text,
          kategori: kategori,
          tanggal: widget.inventory.tanggal ?? '',
        ));
    Navigator.pop(context);
  }

  void _deleteData() {
    context.read<InventoryBloc>().add(DeleteInventoryItem(widget.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryStateCompleteEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data berhasil diperbarui')));
          Navigator.pop(context);
        } else if (state is InventoryError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Detail Inventory",
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
                          _buildDropdownKategori(
                            label: 'Kategori Barang',
                            items: _categories,
                          ),
                          if (_showCustomKategoriField)
                            _buildTextField(
                                'Kategori Lainnya', customKategoriController),
                          _buildTextField(
                              'Nomor Serial', nomorSerialController),
                          _buildTextField('Nama Barang', namaBarangController),
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
    // Add 'Lainnya' option to the list
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
        value: extendedItems.contains(_selectedKategori)
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
}
