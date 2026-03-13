import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/inventory/inventory_bloc.dart';

class InventoryForm extends StatefulWidget {
  const InventoryForm({super.key});

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  final _formKey = GlobalKey<FormState>();
  int _itemCount = 1;
  List<ItemFormData> _items = [];
  List<String> _categories = [];
  bool _isInitialized = false;

  // Daftar pilihan untuk dropdown
  final List<String> _statusBarangOptions = ['Masuk', 'Keluar'];
  final List<String> _kondisiBarangOptions = ['Baik', 'Underperform', 'Buruk'];

  @override
  void initState() {
    super.initState();
    // Jangan akses context di sini untuk GoRouter
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // Ambil quantity dari parameter URL
      final uri = GoRouterState.of(context).uri;
      final quantityParam = uri.queryParameters['quantity'];
      if (quantityParam != null) {
        _itemCount = int.tryParse(quantityParam) ?? 1;
      }

      _initializeItems();
      context.read<InventoryBloc>().add(LoadCategories());
      _isInitialized = true;
    }
  }

  void _initializeItems() {
    _items = List.generate(_itemCount, (index) => ItemFormData());
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // Validasi bahwa semua item memiliki data yang diperlukan
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.nomorSerialController.text.trim().isEmpty ||
          item.namaBarangController.text.trim().isEmpty ||
          item.selectedKategori == null ||
          item.selectedStatusBarang == null ||
          item.selectedKondisiBarang == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lengkapi semua data pada item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Submit semua items
    context.read<InventoryBloc>().add(AddMultipleInventoryItems(items: _items));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'INPUT INVENTARIS ($_itemCount Item${_itemCount > 1 ? 's' : ''})',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InventoryLoading && _categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

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
                child: Column(
                  children: [
                    // Header dengan jumlah items
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[800]),
                          const SizedBox(width: 8),
                          Text(
                            'Anda akan menginput $_itemCount item barang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form items
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return _buildItemForm(index);
                        },
                      ),
                    ),

                    // Submit button
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed:
                            state is InventoryLoading ? null : _submitForm,
                        child: state is InventoryLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                'Submit Semua Data ($_itemCount Items)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
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

  Widget _buildItemForm(int index) {
    final item = _items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue[25],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header item
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Item ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Form fields
          _buildDropdownKategori(
            label: 'Kategori Barang',
            items: _categories,
            item: item,
          ),
          if (item.showCustomKategoriField)
            _buildTextField('Kategori Lainnya', item.customKategoriController),
          _buildTextField('Nomor Serial', item.nomorSerialController),
          _buildTextField('Nama Barang', item.namaBarangController),
          _buildDropdown(
            label: 'Status Barang',
            value: item.selectedStatusBarang,
            items: _statusBarangOptions,
            onChanged: (value) {
              setState(() {
                item.selectedStatusBarang = value;
              });
            },
          ),
          _buildDropdown(
            label: 'Kondisi Barang',
            value: item.selectedKondisiBarang,
            items: _kondisiBarangOptions,
            onChanged: (value) {
              setState(() {
                item.selectedKondisiBarang = value;
              });
            },
          ),
          _buildTextField('Keterangan', item.keteranganController,
              required: false),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: required
            ? (value) =>
                (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: label == 'Keterangan' ? 3 : 1,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
        initialValue: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Pilih $label' : null,
      ),
    );
  }

  Widget _buildDropdownKategori({
    required String label,
    required List<String> items,
    required ItemFormData item,
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
        initialValue: item.selectedKategori,
        items: extendedItems.isEmpty
            ? [const DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya'))]
            : extendedItems
                .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                .toList(),
        onChanged: (value) {
          setState(() {
            item.selectedKategori = value;
            item.showCustomKategoriField = value == 'Lainnya';
          });
        },
        validator: (value) => value == null ? 'Pilih $label' : null,
      ),
    );
  }
}

// Class untuk menyimpan data setiap item
class ItemFormData {
  final TextEditingController nomorSerialController = TextEditingController();
  final TextEditingController namaBarangController = TextEditingController();
  final TextEditingController customKategoriController =
      TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  String? selectedKategori;
  String? selectedStatusBarang;
  String? selectedKondisiBarang;
  bool showCustomKategoriField = false;

  void dispose() {
    nomorSerialController.dispose();
    namaBarangController.dispose();
    customKategoriController.dispose();
    keteranganController.dispose();
  }

  String getKategori() {
    return showCustomKategoriField
        ? customKategoriController.text.trim()
        : selectedKategori ?? '';
  }
}
