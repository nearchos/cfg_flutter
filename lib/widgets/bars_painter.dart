import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class BarsPainter extends CustomPainter {

  BarsPainter({required this.values});

  final Map<int,int> values;
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
    int min = keys.first;
    int max = keys.last;
    int median = values.median();
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

    minTextPainter.paint(canvas, Offset(padding, size.height - minTextPainter.height - padding));
    maxTextPainter.paint(canvas, Offset(size.width - maxTextPainter.width - padding, size.height - maxTextPainter.height - padding));
    medianTextPainter.paint(canvas, Offset(minOffsetX + ((median - min) / (max - min)) * drawableWidth - medianTextPainter.width / 2, padding));

    canvas.drawLine(
        Offset(minOffsetX, maxOffsetY - padding),
        Offset(minOffsetX, size.height - padding - minTextPainter.height),
        Paint()..color = Colors.green..strokeWidth = 1.0
    );
    canvas.drawLine(
        Offset(maxOffsetX, maxOffsetY - padding),
        Offset(maxOffsetX, size.height - padding - minTextPainter.height),
        Paint()..color = Colors.red..strokeWidth = 1.0
    );
    canvas.drawLine(
        Offset(0, minOffsetY),
        Offset(size.width, minOffsetY),
        Paint()..color = Colors.grey..strokeWidth = 0.2
    );
    canvas.drawLine(
        Offset(0, maxOffsetY),
        Offset(size.width, maxOffsetY),
        Paint()..color = Colors.grey..strokeWidth = 0.2
    );
    canvas.drawLine(
        Offset(minOffsetX + ((median - min) / (max - min)) * drawableWidth, maxOffsetY - padding),
        Offset(minOffsetX + ((median - min) / (max - min)) * drawableWidth, size.height - padding - minTextPainter.height),
        Paint()..color = Colors.purple..strokeWidth = 1.0
    );
    // canvas.drawLine(
    //     Offset(minOffsetX + ((average - min) / (max - min)) * drawableWidth, maxOffsetY - padding),
    //     Offset(minOffsetX + ((average - min) / (max - min)) * drawableWidth, size.height - padding - minTextPainter.height),
    //     Paint()..color = Colors.purpleAccent..strokeWidth = 1.0
    // );

    canvas.drawLine(Offset(0, drawableCenterY), Offset(size.width, drawableCenterY), Paint()..color = axisColor);

    for(int key in keys) {
      double keyX = (key - min) / (max-min);
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