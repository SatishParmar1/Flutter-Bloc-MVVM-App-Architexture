import 'package:confetti/confetti.dart';

class ConfettiManager {
  ConfettiManager._();

  static late final ConfettiController _controller;

  static void initialize() {
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  static ConfettiController get controller => _controller;

  static void play() {
    _controller.play();
  }

  static void stop() {
    _controller.stop();
  }

  static void dispose() {
    _controller.dispose();
  }
}
