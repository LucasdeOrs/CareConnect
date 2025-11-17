// widgets/logo_widget.dart
import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.size = 120.0,
    this.useAlternative = false, // Padrão é false
  });

  final double size;
  final bool useAlternative;

  @override
  Widget build(BuildContext context) {
    // Tenta carregar o logo alternativo se useAlternative for true
    // Se você não tiver um, pode apontar os dois para o mesmo arquivo
    final assetName = useAlternative
        ? 'assets/images/CareConnect-only-logo.png' // Use seu logo principal ou um menor
        : 'assets/images/CareConnect-logo.png';

    return Image.asset(
      assetName,
      width: size,
      height: size,
      // Caso o 'logo-alternativo' não exista, ele usa o principal como fallback
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/CareConnect-logo.png', // Fallback
          width: size,
          height: size,
        );
      },
    );
  }
}