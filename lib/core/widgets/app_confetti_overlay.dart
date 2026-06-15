import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../utils/confetti_manager.dart';

class AppConfettiOverlay extends StatelessWidget {
  final Widget child;

  const AppConfettiOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: ConfettiManager.controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }
}
