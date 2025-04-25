import 'package:flutter/material.dart';

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Image.asset('images/logopgascom1.png', height: 100),
        const SizedBox(height: 10),
      ],
    );
  }
}
