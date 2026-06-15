import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../extensions/context_extensions.dart';

enum SvgSource { asset, network, file }

class AppSvgViewer extends StatelessWidget {
  final String path;
  final SvgSource source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final Widget? placeholder;

  const AppSvgViewer({
    super.key,
    required this.path,
    this.source = SvgSource.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    double defaultSize = 24.0;
    if (context.isTablet) {
      defaultSize = 36.0;
    } else if (context.isDesktop) {
      defaultSize = 48.0;
    }

    final targetWidth = width ?? defaultSize;
    final targetHeight = height ?? defaultSize;

    final ColorFilter? colorFilter = color != null
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null;

    final loadingWidget = placeholder ??
        Center(
          child: SizedBox(
            width: targetWidth * 0.5,
            height: targetHeight * 0.5,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        );

    final errorWidget = Center(
      child: Icon(
        Icons.error_outline,
        color: context.colors.error,
        size: targetWidth * 0.6,
      ),
    );

    try {
      switch (source) {
        case SvgSource.network:
          return SvgPicture.network(
            path,
            width: targetWidth,
            height: targetHeight,
            fit: fit,
            colorFilter: colorFilter,
            placeholderBuilder: (BuildContext context) => loadingWidget,
          );
        case SvgSource.file:
          final file = File(path);
          if (!file.existsSync()) return errorWidget;
          return SvgPicture.file(
            file,
            width: targetWidth,
            height: targetHeight,
            fit: fit,
            colorFilter: colorFilter,
            placeholderBuilder: (BuildContext context) => loadingWidget,
          );
        case SvgSource.asset:
          return SvgPicture.asset(
            path,
            width: targetWidth,
            height: targetHeight,
            fit: fit,
            colorFilter: colorFilter,
            placeholderBuilder: (BuildContext context) => loadingWidget,
          );
      }
    } catch (e) {
      return errorWidget;
    }
  }
}
