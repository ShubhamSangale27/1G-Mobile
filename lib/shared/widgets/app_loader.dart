import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Branded loading indicator for full-screen or inline use.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message, this.size = 36});

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay shown during async actions (e.g. form submit).
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, required this.loading, required this.child, this.message});

  final bool loading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: AppLoader(message: message),
            ),
          ),
      ],
    );
  }
}
