import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSSpacing.dart';

/// Design System v2.0 — Shimmer loading placeholder USE3D.
///
/// Usado como placeholder enquanto dados carregam.
class DSShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const DSShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = DSSpacing.radiusSm,
  });

  /// Shimmer em formato de card de métrica.
  factory DSShimmer.metricCard({double height = 120}) {
    return DSShimmer(
      width: double.infinity,
      height: height,
      borderRadius: DSSpacing.radiusLg,
    );
  }

  /// Shimmer em formato de linha de lista.
  factory DSShimmer.listTile() {
    return const DSShimmer(
      width: double.infinity,
      height: 72,
      borderRadius: DSSpacing.radiusMd,
    );
  }

  /// Shimmer circular (avatar).
  factory DSShimmer.circle({double size = DSSpacing.avatarMd}) {
    return DSShimmer(
      width: size,
      height: size,
      borderRadius: DSSpacing.radiusFull,
    );
  }

  @override
  State<DSShimmer> createState() => _DSShimmerState();
}

class _DSShimmerState extends State<DSShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                colors.greyLightest,
                colors.greyLighter.withValues(alpha: 0.5),
                colors.greyLightest,
              ],
            ),
          ),
        );
      },
    );
  }
}
