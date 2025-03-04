import 'package:flutter/material.dart';
import 'package:inventrack/bloc/bloc.dart';

class CustomBarWidget extends StatelessWidget {
  const CustomBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), // Menggunakan opacity
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('images/logoinventrack1.png', width: 60),
          const Text("INVENTRACK",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0D47A1)),
            onPressed: () => context.read<AuthBloc>().add(AuthEventLogout()),
          ),
        ],
      ),
    );
  }
}
