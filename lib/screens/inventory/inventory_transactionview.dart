import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/auth/auth_bloc.dart';
import 'package:inventrack/bloc/inventory/inventory_bloc.dart';
import 'package:inventrack/models/inventory.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventrack/routes/router_name.dart';

class InventoryTransactionView extends StatefulWidget {
  final String? serialNumber;
  const InventoryTransactionView({super.key, this.serialNumber});

  @override
  State<InventoryTransactionView> createState() =>
      _InventoryTransactionViewState();
}

class _InventoryTransactionViewState extends State<InventoryTransactionView>
    with SingleTickerProviderStateMixin {
  final InventoryBloc _inventoryBloc = InventoryBloc();

  String _startDate = DateFormat('dd-MM-yyyy')
      .format(DateTime.now().subtract(const Duration(days: 30)));
  String _endDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  String? _selectedStatus;
  String? _selectedCategory;

  final List<String> _statusOptions = ['Semua Status', 'Masuk', 'Keluar'];
  List<String> _categoryOptions = ['Semua Kategori'];
  bool _isLoadingCategories = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();
    _selectedStatus = _statusOptions[0];
    _selectedCategory = _categoryOptions[0];
    if (widget.serialNumber != null && widget.serialNumber!.isNotEmpty) {
      _searchController.text = widget.serialNumber!;
      _searchKeyword = widget.serialNumber!.toLowerCase();
    }

    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
      });
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection("inventory")
          .doc("data")
          .collection("items")
          .get();
      Set<String> uniqueCategories = {"Semua Kategori"};
      for (var doc in snapshot.docs) {
        final item = Inventory.fromJson(doc.data());
        if (item.kategori != null && item.kategori!.isNotEmpty) {
          uniqueCategories.add(item.kategori!);
        }
      }

      setState(() {
        _categoryOptions = uniqueCategories.toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd-MM-yyyy').parse(_startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _startDate = DateFormat('dd-MM-yyyy').format(date);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd-MM-yyyy').parse(_endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _endDate = DateFormat('dd-MM-yyyy').format(date);
      });
    }
  }

  Widget _buildTransactionCard(Inventory transaction, int index) {
    Color statusColor = transaction.status?.toLowerCase() == 'masuk'
        ? Colors.green[100]!
        : Colors.red[100]!;

    return AnimatedOpacity(
      opacity: 1,
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: Card(
        color: statusColor,
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final authState = context.read<AuthBloc>().state;
            bool hasAccess = false;

            if (authState is AuthStateAuthenticated) {
              final role = authState.handle.toLowerCase();
              hasAccess = role != 'user' || role != 'admin';
            }

            if (hasAccess) {
              try {
                if (transaction.id.isNotEmpty) {
                  context.goNamed(
                    Routes.inventoryTransactionDetail,
                    pathParameters: {"id": transaction.id},
                    extra: transaction,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Invalid transaction ID :  ${transaction.id}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigation error: $e')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Anda tidak memiliki akses ke detail.')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Barang: ${transaction.namaBarang ?? '-'}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                _infoText("Nomor Serial", transaction.nomorSerial),
                _infoText("Kategori", transaction.kategori),
                _infoText("Kondisi", transaction.kondisi),
                _infoText("Status", transaction.status),
                _infoText("Keterangan", transaction.keterangan),
                _infoText("Tanggal", transaction.tanggal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        "$label: ${value ?? '-'}",
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickStartDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Dari: $_startDate",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _pickEndDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Sampai: $_endDate",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSelectors() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatus,
                hint: const Text("Status"),
                onChanged: (String? value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                items: _statusOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoadingCategories
                ? const Center(
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      hint: const Text("Kategori"),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      items: _categoryOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Cari berdasarkan nama barang atau nomor serial...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final contentWidth = isTablet ? screenWidth * 0.7 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text("TRANSAKSI INVENTORY",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildSearchField(),
                    _buildDateRangeSelector(),
                    const SizedBox(height: 12),
                    _buildFilterSelectors(),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: contentWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<List<Inventory>>(
                      stream: _inventoryBloc.streamInventoryTransactions(
                        startDate: _startDate,
                        endDate: _endDate,
                        status: _selectedStatus == 'Semua Status'
                            ? null
                            : _selectedStatus,
                        category: _selectedCategory == 'Semua Kategori'
                            ? null
                            : _selectedCategory,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text("Tidak ada data transaksi."));
                        }

                        final transactions =
                            snapshot.data!.where((transaction) {
                          final nama =
                              transaction.namaBarang?.toLowerCase() ?? '';
                          final serial =
                              transaction.nomorSerial?.toLowerCase() ?? '';
                          return nama.contains(_searchKeyword) ||
                              serial.contains(_searchKeyword);
                        }).toList();

                        if (transactions.isEmpty) {
                          return const Center(
                              child: Text("Tidak ditemukan hasil pencarian."));
                        }

                        return ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) =>
                              _buildTransactionCard(transactions[index], index),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
