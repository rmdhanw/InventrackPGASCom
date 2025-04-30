import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';
import 'package:inventrack/widgets/header_widget.dart'; // Import HeaderWidget

class CarpoolMenu extends StatelessWidget {
  const CarpoolMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLogout) context.goNamed(Routes.login);
      },
      child: Scaffold(
        body: Column(
          children: [
            const HeaderWidget(), // Panggil HeaderWidget yang baru
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final menu = _menuItems[index];

                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => context.goNamed(menu['route']),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(menu['icon'],
                                size: 60, color: Colors.blue.shade800),
                            const SizedBox(height: 10),
                            Text(
                              menu['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.request_page,
      'title': "Request Carpool",
      'route': Routes.carpoolRequest
    },
    {
      'icon': Icons.library_add,
      'title': "Form Carpool",
      'route': Routes.carpoolForm
    },
    {
      'icon': Icons.view_list,
      'title': "View Carpool Requests",
      'route': Routes.carpoolViewRequest
    },
    {
      'icon': Icons.view_list,
      'title': "View Carpool Datas",
      'route': Routes.carpoolView
    },
  ];
}
