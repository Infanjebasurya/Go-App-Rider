import 'package:flutter/material.dart';
import 'package:goapp/core/theme/app_colors.dart';

abstract final class SnackBarUtils {
  static const Duration defaultDuration = Duration(seconds: 2);

  static SnackBar build(
    String message, {
    Duration duration = defaultDuration,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
    ShapeBorder? shape,
    EdgeInsetsGeometry? margin,
  }) {
    final SnackBarBehavior resolvedBehavior =
        behavior ?? SnackBarBehavior.floating;
    final ShapeBorder resolvedShape =
        shape ??
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    final Color resolvedBackgroundColor =
        backgroundColor ?? AppColors.hexFF1A1A1A;

    final EdgeInsetsGeometry? resolvedMargin =
        resolvedBehavior == SnackBarBehavior.floating
        ? (margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16))
        : null;

    return SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: resolvedBackgroundColor,
      behavior: resolvedBehavior,
      shape: resolvedShape,
      margin: resolvedMargin,
    );
  }

  static SnackBar buildError(
    String message, {
    Duration duration = defaultDuration,
  }) {
    return build(
      message,
      duration: duration,
      backgroundColor: AppColors.hexFFE53935,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  static void show(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
    ShapeBorder? shape,
    EdgeInsetsGeometry? margin,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      build(
        message,
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: behavior,
        shape: shape,
        margin: margin,
      ),
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(buildError(message, duration: duration));
  }
}
