import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../extensions/context_extensions.dart';

enum LottieSource { asset, network, file }

class AppLottieViewer extends StatelessWidget {
  final String path;
  final LottieSource source;
  final double? width;
  final double? height;
  final bool repeat;
  final bool animate;
  final double speed;
  final BoxFit fit;

  const AppLottieViewer({
    super.key,
    required this.path,
    this.source = LottieSource.asset,
    this.width,
    this.height,
    this.repeat = true,
    this.animate = true,
    this.speed = 1.0,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    double defaultSize = 150.0;
    if (context.isTablet) {
      defaultSize = 250.0;
    } else if (context.isDesktop) {
      defaultSize = 350.0;
    }

    final targetWidth = width ?? defaultSize;
    final targetHeight = height ?? defaultSize;

    final loadingWidget = Center(
      child: SizedBox(
        width: targetWidth * 0.3,
        height: targetHeight * 0.3,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );

    final errorWidget = Center(
      child: Icon(
        Icons.movie_creation_outlined,
        color: context.colors.outline,
        size: targetWidth * 0.5,
      ),
    );

    try {
      switch (source) {
        case LottieSource.network:
          return Lottie.network(
            path,
            width: targetWidth,
            height: targetHeight,
            repeat: repeat,
            animate: animate,
            fit: fit,
            decoder: (bytes) => LottieComposition.fromBytes(bytes),
            frameBuilder: (context, child, composition) {
              if (composition == null) return loadingWidget;
              return child;
            },
            errorBuilder: (context, error, stackTrace) => errorWidget,
          );
        case LottieSource.file:
          final file = File(path);
          if (!file.existsSync()) return errorWidget;
          return Lottie.file(
            file,
            width: targetWidth,
            height: targetHeight,
            repeat: repeat,
            animate: animate,
            fit: fit,
            frameBuilder: (context, child, composition) {
              if (composition == null) return loadingWidget;
              return child;
            },
            errorBuilder: (context, error, stackTrace) => errorWidget,
          );
        case LottieSource.asset:
          return Lottie.asset(
            path,
            width: targetWidth,
            height: targetHeight,
            repeat: repeat,
            animate: animate,
            fit: fit,
            frameBuilder: (context, child, composition) {
              if (composition == null) return loadingWidget;
              return child;
            },
            errorBuilder: (context, error, stackTrace) => errorWidget,
          );
      }
    } catch (e) {
      return errorWidget;
    }
  }
}
