import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.size = 120.0,
    this.useAlternative = false,
  });

  final double size;
  final bool useAlternative;

  @override
  Widget build(BuildContext context) {
    final assetName = useAlternative
        ? 'assets/images/CareConnect-only-logo.png'
        : 'assets/images/CareConnect-logo.png';

    return Image.asset(
      assetName,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/CareConnect-logo.png',
          width: size,
          height: size,
        );
      },
    );
  }
}