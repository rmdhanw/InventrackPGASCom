import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';
import 'package:inventrack/widgets/header_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLogout) context.goNamed(Routes.login);
      },
      child: Scaffold(
        body: Column(
          children: [
            HeaderWidget(),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    ..._menuItems.map((item) => _buildMenuItem(context,
                        item['icon']!, item['title']!, item['route']!)),
                    const SizedBox(height: 60),
                    Image.asset('images/logopgascom1.png', height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Item menu utama
  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, String route) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).goNamed(route),
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade800, size: 40),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade800),
            ),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.car_rental_sharp,
      'title': "CARPOOL",
      'route': Routes.carpoolMenu
    },
    {
      'icon': Icons.inventory,
      'title': "INVENTORY",
      'route': Routes.inventoryMenu
    },
    {'icon': Icons.qr_code, 'title': "SCAN QR", 'route': Routes.scanQR},
    {'icon': Icons.info, 'title': "INFORMATION", 'route': Routes.information},
  ];
}
