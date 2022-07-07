import 'package:flutter/material.dart';

class BubblePainter extends CustomPainter {
  BubblePainter(
      {required this.color, required this.radius, this.heightArrow = 10});

  final Color color;
  final double radius;

  final double heightArrow;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          0,
          size.width,
          size.height - heightArrow,
          Radius.circular(radius),
        ),
        Paint()
          ..color = this.color
          ..style = PaintingStyle.fill);

    final Path path = Path();
    path.moveTo(centerX, size.height);
    path.lineTo(centerX - 10, size.height - heightArrow);
    path.lineTo(centerX + 10, size.height - heightArrow);
    path.close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
