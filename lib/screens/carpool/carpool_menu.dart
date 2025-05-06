import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/routes/router_name.dart';
import 'package:inventrack/widgets/header_widget.dart';

class CarpoolMenu extends StatelessWidget {
  const CarpoolMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLogout) context.goNamed(Routes.login);
      },
      child: Scaffold(
        body: Column(
          children: [
            const HeaderWidget(),
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
                      itemCount: _menuItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        final menu = _menuItems[index];
                        return _AnimatedMenuCard(
                          icon: menu['icon'],
                          title: menu['title'],
                          routeName: menu['route'],
                        );
                      },
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
      'icon': Icons.hail,
      'title': "Request User",
      'route': Routes.carpoolRequest,
    },
    {
      'icon': Icons.library_add,
      'title': "Bypass Carpool",
      'route': Routes.carpoolForm,
    },
    {
      'icon': Icons.card_travel,
      'title': "Approval Carpool",
      'route': Routes.carpoolViewRequest,
    },
    {
      'icon': Icons.car_rental,
      'title': "Carpool Services",
      'route': Routes.carpoolView,
    },
  ];
}

class _AnimatedMenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String routeName;

  const _AnimatedMenuCard({
    required this.icon,
    required this.title,
    required this.routeName,
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
        onTap: () => context.goNamed(widget.routeName),
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
