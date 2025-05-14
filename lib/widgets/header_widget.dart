import 'package:flutter/material.dart';
import 'custombar_widget.dart';

class HeaderWidget extends StatelessWidget {
  final bool showLogout;
  const HeaderWidget({super.key, required this.showLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset('images/pipe.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: CustomBarWidget(
              showLogout: showLogout,
            ),
          ),
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
