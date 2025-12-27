import 'package:flutter/material.dart';

class VendoraLogo extends StatelessWidget {
  final double? size;
  final bool showTagline;

  const VendoraLogo({
    super.key,
    this.size,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stylized V icon
            Container(
              width: size ?? 40,
              height: size ?? 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: VIconPainter(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Vendora',
              style: TextStyle(
                fontSize: (size ?? 40) * 0.7,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Your Style, Delivered.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

class VIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;

    final path = Path();
    // Draw a stylized V shape with arrows
    path.moveTo(size.width * 0.2, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.2);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

