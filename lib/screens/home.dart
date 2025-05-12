import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';
import 'package:inventrack/widgets/header_widget.dart';
import 'package:inventrack/widgets/logo_pgascom.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTabletOrLarger = screenSize.width >= 600;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLogout) context.goNamed(Routes.login);
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! AuthStateAuthenticated) {
              return const Center(child: CircularProgressIndicator());
            }

            final handle = state.handle;

            final menuItems = _menuItems.where((item) {
              if (handle == 'user') {
                return item['title'] == "CARPOOL" ||
                    item['title'] == "INVENTORY";
              }
              return true;
            }).toList();
            return Column(
              children: [
                const HeaderWidget(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = isTabletOrLarger ? 2 : 1;
                            return Column(
                              children: [
                                const SizedBox(height: 20),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 15,
                                    childAspectRatio: 3.5,
                                  ),
                                  itemCount: menuItems.length,
                                  itemBuilder: (context, index) {
                                    final item = menuItems[index];
                                    return _AnimatedMenuItem(
                                      icon: item['icon'],
                                      title: item['title'],
                                      routeName: item['route'],
                                    );
                                  },
                                ),
                                const SizedBox(height: 60),
                                const CompanyLogo(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.car_rental_sharp,
      'title': "CARPOOL",
      'route': Routes.carpoolMenu,
    },
    {
      'icon': Icons.inventory,
      'title': "INVENTORY",
      'route': Routes.inventoryMenu,
    },
    {
      'icon': Icons.person_add,
      'title': "REGISTER USER",
      'route': Routes.register,
    },
  ];
}

class _AnimatedMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String routeName;

  const _AnimatedMenuItem({
    required this.icon,
    required this.title,
    required this.routeName,
  });

  @override
  State<_AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<_AnimatedMenuItem> {
  double _scale = 1.0;

  void _onTapDown(_) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(_) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () => GoRouter.of(context).goNamed(widget.routeName),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.blue.shade800, size: 32),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
