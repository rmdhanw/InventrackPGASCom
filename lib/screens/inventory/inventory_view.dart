import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/models/inventory.dart';
import 'package:inventrack/routes/router_name.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  bool isLoading = true;
  List<String> categories = ["Semua"];
  String? selectedCategory;

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // Stream untuk data inventory
  Stream<List<Inventory>>? _inventoryStream;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _setupInventoryStream();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat kategori-kategori unik
  Future<void> _loadCategories() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection("inventory")
          .doc("data")
          .collection("items")
          .get();

      // Ekstrak kategori unik
      Set<String> uniqueCategories = {"Semua"};
      for (var doc in snapshot.docs) {
        if (doc.data()['kategori'] != null &&
            doc.data()['kategori'].isNotEmpty) {
          uniqueCategories.add(doc.data()['kategori']);
        }
      }

      setState(() {
        categories = uniqueCategories.toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Setup stream inventory items
  void _setupInventoryStream() {
    _inventoryStream = FirebaseFirestore.instance
        .collection("inventory")
        .doc("data")
        .collection("items")
        .snapshots()
        .map((snapshot) {
      List<Inventory> items = [];
      for (var doc in snapshot.docs) {
        Inventory item = Inventory.fromJson(doc.data());
        item.id = doc.id; // Gunakan document ID sebagai item ID
        items.add(item);
      }
      return items;
    });
  }

  // Filter items berdasarkan kategori dan pencarian
  List<Inventory> filterItems(List<Inventory> items) {
    return items.where((item) {
      // Filter kategori
      bool categoryMatch = selectedCategory == null ||
          selectedCategory == "Semua" ||
          item.kategori == selectedCategory;

      // Filter pencarian
      bool searchMatch = searchQuery.isEmpty ||
          (item.namaBarang?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false) ||
          (item.nomorSerial
                  ?.toLowerCase()
                  .contains(searchQuery.toLowerCase()) ??
              false) ||
          (item.kategori?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);

      return categoryMatch && searchMatch;
    }).toList();
  }

  Future<void> _deleteItem(String itemId) async {
    final BuildContext currentContext = context;
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Konfirmasi Hapus"),
            content:
                const Text("Apakah Anda yakin ingin menghapus barang ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;

    if (confirmDelete) {
      try {
        // Try using the DeleteInventoryItem event from the bloc
        try {
          final bloc = BlocProvider.of<InventoryBloc>(context);
          bloc.add(DeleteInventoryItem(itemId));
        } catch (blocError) {
          // Fallback to direct Firestore deletion if bloc approach fails
          await FirebaseFirestore.instance
              .collection("inventory")
              .doc("data")
              .collection("items")
              .doc(itemId)
              .delete();
        }

        // Show success message
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Gagal menghapus barang: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "INVENTORY DATA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // Navigate to add item page
              context.goNamed(Routes.inventoryForm);
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildInventoryTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Cari barang...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Category filter
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: "Pilih Kategori",
            ),
            value: selectedCategory,
            items: categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable() {
    final authState = context.read<AuthBloc>().state;
    bool hasAccess = false;

    if (authState is AuthStateAuthenticated) {
      final role = authState.handle.toLowerCase();
      hasAccess = role != 'user' && role != 'admin';
    }

    return StreamBuilder<List<Inventory>>(
      stream: _inventoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("Tidak ada data barang yang ditemukan"));
        }

        // Filter items
        final items = filterItems(snapshot.data!);

        if (items.isEmpty) {
          return const Center(
              child: Text("Tidak ada data barang yang ditemukan"));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 15,
              horizontalMargin: 10,
              headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
              columns: [
                DataColumn(
                    label: Text('No',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Kategori Barang',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Nomor Serial',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Nama Barang',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                if (hasAccess)
                  DataColumn(
                      label: Text('Action',
                          style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(items.length, (index) {
                final item = items[index];
                return DataRow(
                  cells: [
                    DataCell(Center(child: Text('${index + 1}'))),
                    DataCell(Text(item.kategori ?? '-')),
                    DataCell(Text(item.nomorSerial ?? '-')),
                    DataCell(Text(item.namaBarang ?? '-')),
                    if (hasAccess) DataCell(_buildActionButtons(item)),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Inventory item) {
    return IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Pilih Tindakan"),
              content: SizedBox(
                width: double.minPositive,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.blue),
                      title: const Text("Edit"),
                      onTap: () {
                        Navigator.pop(context);
                        context.goNamed(
                          Routes.inventoryViewDetail,
                          pathParameters: {"id": item.nomorSerial ?? ""},
                          extra: item,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text("Hapus"),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteItem(item.nomorSerial ?? "");
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.transfer_within_a_station,
                          color: Colors.green),
                      title: const Text("Transaksi"),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to transaction form page
                        context.goNamed(
                          Routes.inventoryTransactionForm,
                          queryParameters: {"id": item.nomorSerial ?? ""},
                          extra: item,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.purple),
                      title: const Text("History Transaksi"),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to transaction history page
                        context.goNamed(
                          Routes.inventoryTransactionView,
                          queryParameters: {"id": item.nomorSerial ?? ""},
                          extra: item,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
