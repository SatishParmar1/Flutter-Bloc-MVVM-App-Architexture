import 'package:flutter/material.dart';
import 'logger.dart';

class LifecycleWatcher extends WidgetsBindingObserver {
  final Function(AppLifecycleState)? onStateChanged;

  LifecycleWatcher({this.onStateChanged});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info('App Lifecycle State changed: ${state.name}', tag: 'LifecycleWatcher');
    if (onStateChanged != null) {
      onStateChanged!(state);
    }
  }
}
