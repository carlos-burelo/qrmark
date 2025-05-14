import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;

  const Background({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // colors: [Color(0xff09182c), Color(0xff0a171e), Color(0xff0a1620)],
          colors: [
            Color.fromARGB(255, 8, 10, 43),
            Color.fromARGB(255, 4, 13, 33),
            Color.fromARGB(255, 0, 13, 32),
          ],
          stops: [0, 0.5, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
