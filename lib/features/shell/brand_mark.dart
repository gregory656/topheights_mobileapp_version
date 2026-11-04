import 'package:flutter/material.dart';

import '../../app/top_heights_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.dark = false});
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF204E3D) : BrandColors.forest,
        borderRadius: BorderRadius.circular(size * .34),
      ),
      child: CustomPaint(painter: _MarkPainter(dark: dark)),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final white = Paint()
      ..color = const Color(0xFFF7F5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * .065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final leaf = Paint()..color = BrandColors.leaf;
    final path = Path()
      ..moveTo(unit * .22, unit * .68)
      ..lineTo(unit * .4, unit * .46)
      ..lineTo(unit * .54, unit * .61)
      ..lineTo(unit * .78, unit * .32);
    canvas.drawPath(path, white);
    canvas.drawCircle(Offset(unit * .77, unit * .29), unit * .075, leaf);
    final base = Path()
      ..moveTo(unit * .2, unit * .76)
      ..quadraticBezierTo(unit * .5, unit * .68, unit * .8, unit * .76);
    canvas.drawPath(base, white..strokeWidth = unit * .045);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) =>
      dark != oldDelegate.dark;
}
