import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomTransitionBuilders {
  CustomTransitionBuilders._();

  static Widget fadeTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Page<T> fadeTransitionPage<T>({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
