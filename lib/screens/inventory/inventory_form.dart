import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/bloc/inventory/inventory_bloc.dart';

class InventoryForm extends StatefulWidget {
  const InventoryForm({super.key});

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  final _formKey = GlobalKey<FormState>();
  final nomorSerialController = TextEditingController();
  final namaBarangController = TextEditingController();
  final customKategoriController = TextEditingController();

  String? _selectedKategori;
  bool _showCustomKategoriField = false;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    // Load categories when the form is initialized
    context.read<InventoryBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    nomorSerialController.dispose();
    namaBarangController.dispose();
    customKategoriController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final kategori = _showCustomKategoriField
        ? customKategoriController.text.trim()
        : _selectedKategori ?? '';

    context.read<InventoryBloc>().add(AddInventoryItem(
          kategori: kategori,
          nomorSerial: nomorSerialController.text.trim(),
          namaBarang: namaBarangController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'INPUT INVENTARIS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.blue,
      body: BlocConsumer<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventorySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          } else if (state is InventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is InventoryLoading && _categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // Update categories when they are loaded
          if (state is InventoryLoaded || state is CategoriesLoaded) {
            if (state is InventoryLoaded) {
              _categories = state.categories;
            } else if (state is CategoriesLoaded) {
              _categories = (state).categories;
            }
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 10),
                    _buildDropdownKategori(
                      label: 'Kategori Barang',
                      items: _categories,
                    ),
                    if (_showCustomKategoriField)
                      _buildTextField(
                          'Kategori Lainnya', customKategoriController),
                    _buildTextField('Nomor Serial', nomorSerialController),
                    _buildTextField('Nama Barang', namaBarangController),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
        value: _selectedKategori,
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
