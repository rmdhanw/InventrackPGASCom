import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/models/inventory.dart';
import 'package:inventrack/routes/router_name.dart';

class InventoryTransactionView extends StatefulWidget {
  const InventoryTransactionView({super.key});

  @override
  State<InventoryTransactionView> createState() =>
      _InventoryTransactionViewState();
}

class _InventoryTransactionViewState extends State<InventoryTransactionView> {
  bool isLoading = true;
  List<Inventory> inventoryItems = [];
  String? selectedCategory;
  List<String> categories = ["Semua"];

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get reference to the inventory collection
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection("inventory")
          .doc("transaction")
          .collection("items")
          .get();

      // Convert snapshots to inventory items
      List<Inventory> items = [];
      for (var doc in snapshot.docs) {
        Inventory item = Inventory.fromJson(doc.data());
        item.id = doc.id; // Use document ID as the item ID
        items.add(item);
      }

      // Get unique categories
      Set<String> uniqueCategories = {"Semua"};
      for (var item in items) {
        if (item.kategori != null && item.kategori!.isNotEmpty) {
          uniqueCategories.add(item.kategori!);
        }
      }

      setState(() {
        inventoryItems = items;
        categories = uniqueCategories.toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading inventory data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Inventory> get filteredItems {
    return inventoryItems.where((item) {
      // Apply category filter
      bool categoryMatch = selectedCategory == null ||
          selectedCategory == "Semua" ||
          item.kategori == selectedCategory;

      // Apply search filter
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

  Future<void> _confirmDeleteItem(String itemId) async {
    final BuildContext currentContext = context;
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Konfirmasi Hapus"),
            content:
                const Text("Apakah Anda yakin ingin menghapus barang ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteItem(itemId);
                },
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection("inventory")
            .doc(itemId)
            .delete();

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dihapus')),
        );

        // Reload data
        _loadInventoryData();
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
          "INVENTORY MANAGEMENT",
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
              // context.goNamed(Routes.addInventory);
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
    final items = filteredItems;

    if (items.isEmpty) {
      return const Center(child: Text("Tidak ada data barang yang ditemukan"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 15,
          horizontalMargin: 10,
          headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
          columns: const [
            DataColumn(
                label:
                    Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Kategori Barang',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Nomor Serial',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Nama Barang',
                    style: TextStyle(fontWeight: FontWeight.bold))),
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
                DataCell(_buildActionButtons(item)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Inventory item) {
    return IconButton(
      icon: Icon(Icons.edit, color: Colors.blue),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Pilih Tindakan"),
              content: SizedBox(
                width: double.minPositive,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: Colors.blue),
                      title: Text("Edit"),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to edit page
                        // context.goNamed(
                        //   Routes.editInventory,
                        //   pathParameters: {"id": item.id ?? ""},
                        //   extra: item,
                        // );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text("Hapus"),
                      onTap: () {
                        Navigator.pop(context);
                        // _deleteItem();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.transfer_within_a_station,
                          color: Colors.green),
                      title: Text("Transaksi"),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to transaction page
                        // context.goNamed(
                        //   Routes.inventoryTransaction,
                        //   pathParameters: {"id": item.id ?? ""},
                        // );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.history, color: Colors.purple),
                      title: Text("History Transaksi"),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to history page
                        // context.goNamed(
                        //   Routes.transactionHistory,
                        //   pathParameters: {"id": item.id ?? ""},
                        // );
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
