import 'package:flutter/material.dart';

import 'shimmer_box.dart';

/// @deprecated Prefer [ShimmerBox] directly. Kept for backward compatibility.
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key, this.height = 120, this.width, this.borderRadius = 10});

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: width, height: height, borderRadius: borderRadius);
  }
}
