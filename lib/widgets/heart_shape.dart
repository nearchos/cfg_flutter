import 'package:flutter/material.dart';

class HeartShape extends OutlinedBorder {

  final BorderSide side;
  final Color shapeColor;

  const HeartShape({this.side = const BorderSide(), this.shapeColor = Colors.grey});

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return HeartShape(side: side ?? const BorderSide());
  }

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    var path = Path()
      ..addRect(rect.deflate(25))
      ..close();
    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    double width = rect.width * 2;
    double height = rect.height * 2;
    Path path = Path();
    path.moveTo(0.5 * width, height * 0.4);
    path.cubicTo(0.2 * width, height * 0.1, -0.25 * width, height * 0.6,
        0.5 * width, height);
    path.moveTo(0.5 * width, height * 0.4);
    path.cubicTo(0.8 * width, height * 0.1, 1.25 * width, height * 0.6,
        0.5 * width, height);
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    Paint paint = Paint();
    paint
      ..color = shapeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    // Paint paint1 = Paint();
    // paint1
    //   ..color = Colors.amber
    //   ..style = PaintingStyle.fill
    //   ..strokeWidth = 0;

    double width = rect.width * 2;
    double height = rect.height * 2;

    Path path = Path();
    path.moveTo(0.5 * width, height * 0.4);
    path.cubicTo(0.2 * width, height * 0.1, -0.25 * width, height * 0.6,
        0.5 * width, height);
    path.moveTo(0.5 * width, height * 0.4);
    path.cubicTo(0.8 * width, height * 0.1, 1.25 * width, height * 0.6,
        0.5 * width, height);

    // canvas.drawPath(path, paint1);
    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return scale(t);
  }
}