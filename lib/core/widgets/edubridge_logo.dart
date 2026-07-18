import 'package:flutter/material.dart';

/// EduBridge brand mark — consistent with the web and mobile apps: a navy
/// rounded square with a white lowercase "e".
class EduBridgeMark extends StatelessWidget {
  final double size;
  const EduBridgeMark({super.key, this.size = 34});

  static const Color navy = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      alignment: Alignment.center,
      child: Text(
        'e',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.56,
          height: 1,
        ),
      ),
    );
  }
}

/// EduBridge wordmark — "edu" in [baseColor] followed by an accented "Bridge",
/// matching the web/mobile lockup.
class EduBridgeWordmark extends StatelessWidget {
  final double fontSize;
  final Color baseColor;
  const EduBridgeWordmark({
    super.key,
    this.fontSize = 16,
    this.baseColor = Colors.white,
  });

  static const Color accent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: baseColor,
        ),
        children: const [
          TextSpan(text: 'edu'),
          TextSpan(text: 'Bridge', style: TextStyle(color: accent)),
        ],
      ),
    );
  }
}

/// Convenience lockup: mark + wordmark in a row.
class EduBridgeLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final Color baseColor;
  const EduBridgeLogo({
    super.key,
    this.markSize = 34,
    this.fontSize = 16,
    this.baseColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EduBridgeMark(size: markSize),
        SizedBox(width: markSize * 0.34),
        EduBridgeWordmark(fontSize: fontSize, baseColor: baseColor),
      ],
    );
  }
}
