import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';
import 'package:inventrack/widgets/header_widget.dart';

class InventoryMenu extends StatelessWidget {
  const InventoryMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthStateLogout) {
          context.goNamed(Routes.login);
        }

        if (state is! AuthStateAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }
        final handle = state.handle;

        final menuItems = _menuItems.where((item) {
          if (handle == 'user' || handle == 'admin') {
            return item['title'] == "Riwayat Transaksi Barang" ||
                item['title'] == "Data Barang";
          }
          return true;
        }).toList();

        return Scaffold(
          body: Column(
            children: [
              const HeaderWidget(
                showLogout: false,
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (screenWidth > 900) {
                        crossAxisCount = 3;
                      } else if (screenWidth > 600) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        itemCount: menuItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          final menu = menuItems[index];
                          return _AnimatedMenuCard(
                            icon: menu['icon'],
                            title: menu['title'],
                            routeName: menu['route'],
                            onTap: () => _handleMenuTap(context, menu),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuTap(BuildContext context, Map<String, dynamic> menu) {
    if (menu['title'] == "Input Data Barang") {
      _showQuantityDialog(context, isTransaction: false);
    } else if (menu['title'] == "Input Transaksi Barang") {
      _showQuantityDialog(context, isTransaction: true);
    } else {
      context.goNamed(menu['route']);
    }
  }

  void _showQuantityDialog(BuildContext context,
      {required bool isTransaction}) {
    final TextEditingController quantityController = TextEditingController();
    final String dialogTitle =
        isTransaction ? 'Input Jumlah Transaksi' : 'Input Jumlah Data';
    final String dialogContent = isTransaction
        ? 'Masukkan jumlah transaksi barang yang ingin diinputkan:'
        : 'Masukkan jumlah data barang yang ingin diinputkan:';
    final String labelText = isTransaction ? 'Jumlah Transaksi' : 'Jumlah Data';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            dialogTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dialogContent,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: 'Contoh: 5',
                  filled: true,
                  fillColor: Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.numbers, color: Colors.blue),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Masukkan angka yang valid (lebih dari 0)';
                  }
                  if (number > 50) {
                    return 'Maksimal 50 data per input';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final quantity = int.tryParse(quantityController.text);
                if (quantity != null && quantity > 0 && quantity <= 50) {
                  Navigator.of(context).pop();

                  // Navigate berdasarkan jenis menu
                  if (isTransaction) {
                    context.goNamed(
                      Routes.inventoryTransactionForm,
                      queryParameters: {'quantity': quantity.toString()},
                    );
                  } else {
                    context.goNamed(
                      Routes.inventoryForm,
                      queryParameters: {'quantity': quantity.toString()},
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan jumlah yang valid (1-50)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  static final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.library_add,
      'title': "Input Data Barang",
      'route': Routes.inventoryForm,
    },
    {
      'icon': Icons.input,
      'title': "Input Transaksi Barang",
      'route': Routes.inventoryTransactionForm,
    },
    {
      'icon': Icons.history,
      'title': "Riwayat Transaksi Barang",
      'route': Routes.inventoryTransactionView,
    },
    {
      'icon': Icons.list_alt,
      'title': "Data Barang",
      'route': Routes.inventoryView,
    },
  ];
}

class _AnimatedMenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String routeName;
  final VoidCallback? onTap;

  const _AnimatedMenuCard({
    required this.icon,
    required this.title,
    required this.routeName,
    this.onTap,
  });

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard> {
  double _scale = 1.0;
  bool _hovering = false;

  void _onTapDown(_) => setState(() => _scale = 0.95);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap ?? () => context.goNamed(widget.routeName),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hovering ? Colors.blue.shade100 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 60, color: Colors.blue.shade800),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 14 : 16,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
