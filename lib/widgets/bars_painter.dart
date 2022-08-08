import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class BarsPainter extends CustomPainter {

  BarsPainter({required this.values, required this.absMin, required this.absMax, this.selectedStationPrice = 0});

  final Map<int,int> values;
  final int absMin;
  final int absMax;
  final int selectedStationPrice;
  final double padding = 4;
  final double fontSize = 10;
  final double barRadius = 2;
  final Color barColor = Colors.red;
  final Color axisColor = Colors.black;

  @override
  void paint(Canvas canvas, Size size) {

    // preprocessing
    List<int> keys = values.keys.toList();
    keys.sort();
    List<int> allPrices = [];
    for(int key in keys) {
      int numOfStationsWithPrice = values[key]!;
      for(int i = 0; i < numOfStationsWithPrice; i++) {
        allPrices.add(key);
      }
    }
    int min = allPrices.first;
    int max = allPrices.last;
    int quartileStart = allPrices[allPrices.length ~/ 4];
    int quartileEnd = allPrices[3 * allPrices.length ~/ 4];
    int median = allPrices.median();
    int maxNumOfStations = values.values.toList().max;

    final minTextSpan = TextSpan(
      text: '€${min/1000}',
      style: TextStyle(color: Colors.green, fontSize: fontSize),
    );
    final minTextPainter = TextPainter(
      text: minTextSpan,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width);

    final maxTextSpan = TextSpan(
      text: '€${max/1000}',
      style: TextStyle(color: Colors.red, fontSize: fontSize),
    );
    final maxTextPainter = TextPainter(
      text: maxTextSpan,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width);

    final medianTextSpan = TextSpan(
      text: '€${median/1000}',
      style: TextStyle(color: Colors.purple, fontSize: fontSize),
    );
    final medianTextPainter = TextPainter(
      text: medianTextSpan,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width);

    double minOffsetX = padding + minTextPainter.width / 2;
    double maxOffsetX = size.width - maxTextPainter.width / 2 - padding;
    double drawableWidth = maxOffsetX - minOffsetX;
    double minOffsetY = size.height - padding - minTextPainter.height - padding;
    double maxOffsetY = padding + medianTextPainter.height + padding;
    double drawableHeight = minOffsetY - maxOffsetY;
    double drawableCenterY = maxOffsetY + drawableHeight / 2;

    minTextPainter.paint(canvas, Offset(minOffsetX + ((min - absMin) / (absMax - absMin)) * drawableWidth - minTextPainter.width / 2, size.height - minTextPainter.height - padding));
    maxTextPainter.paint(canvas, Offset(minOffsetX + ((max - absMin) / (absMax - absMin)) * drawableWidth - maxTextPainter.width / 2, size.height - maxTextPainter.height - padding));
    medianTextPainter.paint(canvas, Offset(minOffsetX + ((median - absMin) / (absMax - absMin)) * drawableWidth - medianTextPainter.width / 2, padding));

    canvas.drawLine(
        Offset(minOffsetX + (min-absMin) / (absMax - absMin) * drawableWidth, maxOffsetY - padding),
        Offset(minOffsetX + (min-absMin) / (absMax - absMin) * drawableWidth, size.height - padding - minTextPainter.height),
        Paint()..color = Colors.green..strokeWidth = 1.0
    );
    canvas.drawLine(
        Offset(minOffsetX + ((max - absMin) / (absMax - absMin)) * drawableWidth, maxOffsetY - padding),
        Offset(minOffsetX + ((max - absMin) / (absMax - absMin)) * drawableWidth, size.height - padding - minTextPainter.height),
        Paint()..color = Colors.red..strokeWidth = 1.0
    );
    canvas.drawLine(
        Offset(0, minOffsetY),
        Offset(size.width, minOffsetY),
        Paint()..color = Colors.grey..strokeWidth = 0.2
    );
    if(selectedStationPrice != 0) {
      const double triangleSide = 10;
      final double triangleHeight = triangleSide * sqrt(3) / 2;
      double priceX = minOffsetX + ((selectedStationPrice - absMin) / (absMax - absMin)) * drawableWidth;
      double arrowUpCenterY = size.height - padding - minTextPainter.height - triangleHeight;
      double arrowDownCenterY = maxOffsetY - padding + triangleHeight;
      Path hollowRectanglePath = Path()
        ..moveTo(priceX, arrowDownCenterY - triangleHeight)
        ..lineTo(priceX, arrowUpCenterY + triangleHeight);
      canvas.drawPath(
          hollowRectanglePath,
          Paint()..color = Colors.orange..strokeWidth = 1.0..style = PaintingStyle.stroke
      );
      Path arrowUpPath = Path()
        ..moveTo(priceX, arrowUpCenterY)
        ..lineTo(priceX + triangleSide / 2, arrowUpCenterY + triangleHeight)
        ..lineTo(priceX - triangleSide / 2, arrowUpCenterY + triangleHeight)
        ..lineTo(priceX, arrowUpCenterY);
      canvas.drawPath(
          arrowUpPath,
          Paint()..color = Colors.orange..strokeWidth = 1.0
      );
      Path arrowDownPath = Path()
        ..moveTo(priceX, arrowDownCenterY)
        ..lineTo(priceX + triangleSide / 2, arrowDownCenterY - triangleHeight)
        ..lineTo(priceX - triangleSide / 2, arrowDownCenterY - triangleHeight)
        ..lineTo(priceX, arrowDownCenterY);
      canvas.drawPath(
          arrowDownPath,
          Paint()..color = Colors.orange..strokeWidth = 2.0
      );
    }
    canvas.drawRect(
        Rect.fromLTWH(
          minOffsetX + ((quartileStart - absMin) / (absMax - absMin)) * drawableWidth, drawableCenterY - drawableHeight / 2,
          ((quartileEnd - quartileStart) / (absMax - absMin)) * drawableWidth, drawableHeight,
        ),
        Paint()..color = const Color(0x16000000)
    );
    canvas.drawLine(
        Offset(0, maxOffsetY),
        Offset(size.width, maxOffsetY),
        Paint()..color = Colors.grey..strokeWidth = 0.2
    );
    canvas.drawLine(
        Offset(minOffsetX + ((median - absMin) / (absMax - absMin)) * drawableWidth, maxOffsetY - padding),
        Offset(minOffsetX + ((median - absMin) / (absMax - absMin)) * drawableWidth, size.height - padding - minTextPainter.height),
        Paint()..color = Colors.purple..strokeWidth = 1.0
    );
    // canvas.drawLine(
    //     Offset(minOffsetX + ((average - min) / (max - min)) * drawableWidth, maxOffsetY - padding),
    //     Offset(minOffsetX + ((average - min) / (max - min)) * drawableWidth, size.height - padding - minTextPainter.height),
    //     Paint()..color = Colors.purpleAccent..strokeWidth = 1.0
    // );

    canvas.drawLine(Offset(0, drawableCenterY), Offset(size.width, drawableCenterY), Paint()..color = axisColor);

    for(int key in keys) {
      double keyX = (key - absMin) / (absMax-absMin);
      int numOfStations = values[key]!;
      double valueIntensity = numOfStations / maxNumOfStations;
      double barHeight = valueIntensity * (drawableHeight - 2 * padding);
      canvas.drawOval(
          Rect.fromCircle(center: Offset(minOffsetX + keyX * drawableWidth, drawableCenterY - barHeight / 2), radius: barRadius),
          Paint()..color = barColor
      );
      canvas.drawOval(
          Rect.fromCircle(center: Offset(minOffsetX + keyX * drawableWidth, drawableCenterY + barHeight / 2), radius: barRadius),
          Paint()..color = barColor
      );
      canvas.drawRect(
          Rect.fromCenter(center: Offset(minOffsetX + keyX * drawableWidth, drawableCenterY), width: 2 * barRadius, height: barHeight),
          Paint()..color = barColor
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension ListExtension on List<int> {
  int median() {
    return length == 0 ? 0 : this[length ~/ 2];
  }
}

extension MapExtension on Map<int, int> {
  int median() {
    int totalNumOfValues = values.toList().sum;
    int currentSumOfValues = 0;
    int median = 0;
    List<int> sortedKeys = keys.toList();
    sortedKeys.sort();
    for(int key in sortedKeys) {
      currentSumOfValues += this[key]!;
      if(currentSumOfValues >= totalNumOfValues ~/ 2) {
        median = key;
        break;
      }
    }
    return median;
  }
}