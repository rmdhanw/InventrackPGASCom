import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  int _itemCount = 1;
  List<TransactionFormData> _transactions = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final uri = GoRouterState.of(context).uri;
      final quantityParam = uri.queryParameters['quantity'];
      if (quantityParam != null) {
        _itemCount = int.tryParse(quantityParam) ?? 1;
      }

      _initializeTransactions();

      if (widget.nomorSerial != null && widget.nomorSerial!.isNotEmpty) {
        _transactions[0].nomorSerialController.text = widget.nomorSerial!;
        if (widget.inventoryItem != null) {
          _prefillData(0, widget.inventoryItem!);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _searchItem(0);
          });
        }
      }

      _isInitialized = true;
    }
  }

  void _initializeTransactions() {
    _transactions = List.generate(_itemCount, (index) => TransactionFormData());
  }

  @override
  void dispose() {
    for (var transaction in _transactions) {
      transaction.dispose();
    }
    super.dispose();
  }

  void _prefillData(int index, Inventory item) {
    setState(() {
      _transactions[index].selectedKategori = item.kategori;
      _transactions[index].namaBarangController.text = item.namaBarang ?? '';
      _transactions[index].dataPreFilled = true;
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

  void _searchItem(int index) async {
    final nomorSerial = _transactions[index].nomorSerialController.text.trim();
    if (nomorSerial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Masukkan Nomor Serial pada item ${index + 1} terlebih dahulu'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      _transactions[index].isSearching = true;
    });

    bool exists = await _checkNomorSerialExists(nomorSerial);

    if (!mounted) return;

    setState(() {
      _transactions[index].isSearching = false;
    });

    if (exists) {
      context
          .read<InventoryBloc>()
          .add(LoadItemBySerialForTransaction(nomorSerial, index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nomor Serial pada item ${index + 1} tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      _transactions[index].namaBarangController.clear();
      setState(() {
        _transactions[index].selectedKategori = null;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // Validasi bahwa semua transaction memiliki data yang diperlukan
    for (int i = 0; i < _transactions.length; i++) {
      final transaction = _transactions[i];
      if (transaction.nomorSerialController.text.trim().isEmpty ||
          transaction.namaBarangController.text.trim().isEmpty ||
          transaction.selectedKategori == null ||
          transaction.selectedStatus == null ||
          transaction.selectedKondisi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lengkapi semua data pada item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Submit semua transactions
    context
        .read<InventoryBloc>()
        .add(AddMultipleTransactions(transactions: _transactions));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
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
        } else if (state is ItemLoadedForTransaction) {
          setState(() {
            _transactions[state.index].selectedKategori = state.kategori;
            _transactions[state.index].namaBarangController.text =
                state.namaBarang;
            _transactions[state.index].dataPreFilled = true;
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'FORM TRANSAKSI INVENTARIS ($_itemCount Item${_itemCount > 1 ? 's' : ''})',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: Colors.blue,
          body: GestureDetector(
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
                            'Anda akan menginput $_itemCount transaksi barang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form transactions
                    Expanded(
                      child: ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionForm(index);
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
                                'Submit Semua Data ($_itemCount Transaksi)',
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
          ),
        );
      },
    );
  }

  Widget _buildTransactionForm(int index) {
    final transaction = _transactions[index];

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
              'Transaksi ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Form fields
          _buildNomorSerialField(index),
          _buildTextField(
            'Kategori',
            TextEditingController(text: transaction.selectedKategori ?? ''),
            enabled: false,
          ),
          _buildTextField(
            'Nama Barang',
            transaction.namaBarangController,
            enabled: false,
          ),
          _buildDropdownField(
            label: 'Status Barang',
            value: transaction.selectedStatus,
            items: ['Masuk', 'Keluar'],
            onChanged: (val) =>
                setState(() => transaction.selectedStatus = val),
          ),
          _buildDropdownField(
            label: 'Kondisi Barang',
            value: transaction.selectedKondisi,
            items: ['Baik', 'Underperform', 'Buruk'],
            onChanged: (val) =>
                setState(() => transaction.selectedKondisi = val),
          ),
          _buildTextField('Keterangan', transaction.keteranganController,
              required: false),
        ],
      ),
    );
  }

  Widget _buildNomorSerialField(int index) {
    final transaction = _transactions[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: transaction.nomorSerialController,
              enabled: !transaction.dataPreFilled,
              decoration: InputDecoration(
                labelText: 'Nomor Serial',
                filled: true,
                fillColor: transaction.dataPreFilled
                    ? Colors.grey[300]
                    : Colors.blue[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Nomor Serial tidak boleh kosong'
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  transaction.dataPreFilled ? Colors.grey : Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: transaction.dataPreFilled || transaction.isSearching
                ? null
                : () => _searchItem(index),
            icon: transaction.isSearching
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true, bool required = true}) {
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
        validator: required
            ? (value) => value == null || value.isEmpty
                ? '$label tidak boleh kosong'
                : null
            : null,
        maxLines: label == 'Keterangan' ? 3 : 1,
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
        initialValue: value,
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
}

// Class untuk menyimpan data setiap transaction
class TransactionFormData {
  final TextEditingController nomorSerialController = TextEditingController();
  final TextEditingController namaBarangController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  String? selectedKategori;
  String? selectedStatus;
  String? selectedKondisi;
  bool isSearching = false;
  bool dataPreFilled = false;

  void dispose() {
    nomorSerialController.dispose();
    namaBarangController.dispose();
    keteranganController.dispose();
  }
}
