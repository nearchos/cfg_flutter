import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as Math;

class StarShape extends OutlinedBorder {

  final BorderSide side;
  final Color shapeColor;

  const StarShape({this.side = const BorderSide(), this.shapeColor = Colors.grey});

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return StarShape(side: side ?? const BorderSide());
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
    rect = rect.inflate(15);
    var mid = rect.width / 2;
    var min = Math.min(rect.width, rect.height);
    var half = min / 2;
    mid = mid - half;
    var path = Path();
    // top left
    path.moveTo(mid + half * 0.5, half * 0.84);
    // top right
    path.lineTo(mid + half * 1.5, half * 0.84);
    // bottom left
    path.lineTo(mid + half * 0.68, half * 1.45);
    // top tip
    path.lineTo(mid + half * 1.0, half * 0.5);
    // bottom right
    path.lineTo(mid + half * 1.32, half * 1.45);
    // top left
    path.lineTo(mid + half * 0.5, half * 0.84);
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    rect = rect.inflate(15);
    var mid = rect.width / 2;
    var min = Math.min(rect.width, rect.height);
    var half = min / 2;
    mid = mid - half;

    var path = Path();
    // top left
    path.moveTo(mid + half * 0.5, half * 0.84);
    // top right
    path.lineTo(mid + half * 1.5, half * 0.84);
    // bottom left
    path.lineTo(mid + half * 0.68, half * 1.45);
    // top tip
    path.lineTo(mid + half * 1.0, half * 0.5);
    // bottom right
    path.lineTo(mid + half * 1.32, half * 1.45);
    // top left
    path.lineTo(mid + half * 0.5, half * 0.84);
    canvas.drawPath(
      path,
      Paint()..color = shapeColor,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return scale(t);
  }
}