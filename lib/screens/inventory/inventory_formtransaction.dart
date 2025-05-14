import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventrack/bloc/inventory/inventory_bloc.dart';
import 'package:inventrack/models/inventory.dart';

class InventoryTransactionForm extends StatefulWidget {
  final String? nomorSerial;
  final Inventory? inventoryItem;

  const InventoryTransactionForm({
    super.key,
    this.nomorSerial,
    this.inventoryItem,
  });

  @override
  State<InventoryTransactionForm> createState() =>
      _InventoryTransactionFormState();
}

class _InventoryTransactionFormState extends State<InventoryTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  // Controller dan variable
  final nomorSerialController = TextEditingController();
  final namaBarangController = TextEditingController();
  final keteranganController = TextEditingController();

  String? _selectedKategori;
  String? _selectedStatus;
  String? _selectedKondisi;

  bool _isSearching = false;
  bool _dataPreFilled = false;

  @override
  void initState() {
    super.initState();

    // Check if we have prefilled data from navigation
    if (widget.nomorSerial != null && widget.nomorSerial!.isNotEmpty) {
      // Set the nomor serial and trigger search
      nomorSerialController.text = widget.nomorSerial!;

      // If we also have the full inventory item data
      if (widget.inventoryItem != null) {
        _prefillData(widget.inventoryItem!);
      } else {
        // Otherwise search for the item data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchItem();
        });
      }
    }
  }

  void _prefillData(Inventory item) {
    setState(() {
      _selectedKategori = item.kategori;
      namaBarangController.text = item.namaBarang ?? '';
      _dataPreFilled = true;
    });
  }

  Future<bool> _checkNomorSerialExists(String nomorSerial) async {
    final doc = await FirebaseFirestore.instance
        .collection('inventory')
        .doc("data")
        .collection("items")
        .doc(nomorSerial)
        .get();

    return doc.exists;
  }

  void _searchItem() async {
    final nomorSerial = nomorSerialController.text.trim();
    if (nomorSerial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Nomor Serial terlebih dahulu'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Cek apakah nomor serial ada di database
    bool exists = await _checkNomorSerialExists(nomorSerial);

    setState(() {
      _isSearching = false;
    });

    if (exists) {
      // Jika nomor serial ada, maka load data item
      context.read<InventoryBloc>().add(LoadItemBySerial(nomorSerial));
    } else {
      // Jika nomor serial tidak ada
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor Serial tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      // Reset field
      namaBarangController.clear();
      setState(() {
        _selectedKategori = null;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<InventoryBloc>().add(AddTransaction(
            kategori: _selectedKategori ?? '',
            nomorSerial: nomorSerialController.text,
            namaBarang: namaBarangController.text,
            status: _selectedStatus ?? '',
            kondisi: _selectedKondisi ?? '',
            keterangan: keteranganController.text,
          ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventorySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
          _formKey.currentState!.reset();
          nomorSerialController.clear();
          namaBarangController.clear();
          keteranganController.clear();
          setState(() {
            _selectedKategori = null;
            _selectedStatus = null;
            _selectedKondisi = null;
          });
        } else if (state is InventoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is ItemLoaded) {
          setState(() {
            _selectedKategori = state.kategori;
            namaBarangController.text = state.namaBarang;
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "FORM TRANSAKSI INVENTARIS",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Nomor Serial dengan tombol cari
                  _buildNomorSerialField(),

                  // Field yang akan terisi otomatis setelah pencarian
                  _buildTextField('Kategori',
                      TextEditingController(text: _selectedKategori ?? ''),
                      enabled: false),
                  _buildTextField('Nama Barang', namaBarangController,
                      enabled: false),

                  // Field untuk transaksi
                  _buildDropdownField(
                    label: 'Status Barang',
                    value: _selectedStatus,
                    items: ['Masuk', 'Keluar'],
                    onChanged: (val) => setState(() => _selectedStatus = val),
                  ),
                  _buildDropdownField(
                    label: 'Kondisi Barang',
                    value: _selectedKondisi,
                    items: ['Baik', 'Underperform', 'Buruk'],
                    onChanged: (val) => setState(() => _selectedKondisi = val),
                  ),
                  _buildTextField('Keterangan', keteranganController),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Simpan',
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
    );
  }

  Widget _buildNomorSerialField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          // Field input nomor serial
          Expanded(
            child: TextFormField(
              controller: nomorSerialController,
              enabled: !_dataPreFilled, // Disable if data is prefilled
              decoration: InputDecoration(
                labelText: 'Nomor Serial',
                filled: true,
                fillColor: _dataPreFilled ? Colors.grey[300] : Colors.blue[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Nomor Serial tidak boleh kosong'
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Tombol cari
          IconButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _dataPreFilled ? Colors.grey : Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: _dataPreFilled || _isSearching ? null : _searchItem,
            icon: _isSearching
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: enabled ? Colors.blue[100] : Colors.grey[300],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? '$label tidak boleh kosong' : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
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
        validator: (val) => val == null ? 'Pilih $label' : null,
      ),
    );
  }

  @override
  void dispose() {
    nomorSerialController.dispose();
    namaBarangController.dispose();
    keteranganController.dispose();
    super.dispose();
  }
}
