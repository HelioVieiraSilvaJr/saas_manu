import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'DSColors.dart';

/// Imagem de rede com cache automático, shimmer de loading e fallback.
///
/// Substitui `Image.network` em toda a aplicação.
/// Usa [CachedNetworkImage] para evitar re-downloads e melhorar a UX.
///
/// Exemplo:
/// ```dart
/// AppNetworkImage(
///   url: product.imageUrl,
///   width: 80,
///   height: 80,
///   fit: BoxFit.cover,
///   borderRadius: BorderRadius.circular(8),
///   placeholder: Icon(Icons.inventory_2_outlined),
/// )
/// ```
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Widget exibido quando a URL é nula/vazia ou ocorre erro.
  final Widget? placeholder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();

    final hasUrl = url != null && url!.isNotEmpty;

    Widget imageWidget;

    if (hasUrl) {
      imageWidget = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        // Loading: shimmer animado
        placeholder: (context, url) => _buildShimmer(colors),
        // Erro: placeholder padrão
        errorWidget: (context, url, error) => _buildPlaceholder(colors),
        // Evita re-render desnecessário se URL não mudar
        cacheKey: url,
      );
    } else {
      imageWidget = _buildPlaceholder(colors);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildShimmer(DSColors colors) {
    return SizedBox(
      width: width,
      height: height,
      child: _ShimmerBox(color: colors.divider),
    );
  }

  Widget _buildPlaceholder(DSColors colors) {
    return Container(
      width: width,
      height: height,
      color: colors.scaffoldBackground,
      child: Center(
        child:
            placeholder ??
            Icon(
              Icons.image_outlined,
              size: (width != null && width! < 60) ? 20 : 40,
              color: colors.textTertiary.withValues(alpha: 0.4),
            ),
      ),
    );
  }
}

/// Caixa com animação de shimmer para skeleton loading.
class _ShimmerBox extends StatefulWidget {
  final Color color;

  const _ShimmerBox({required this.color});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        color: widget.color.withValues(alpha: _animation.value * 0.6),
      ),
    );
  }
}
