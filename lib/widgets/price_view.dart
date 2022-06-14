import 'package:flutter/material.dart';

class PriceView extends StatelessWidget {

  const PriceView({Key? key, required this.price, this.basicFontSize = 18, this.fontWeight = FontWeight.normal, this.color = Colors.black, this.borderColor = Colors.white10}) : super(key: key);

  final double price;
  final double basicFontSize;
  final FontWeight fontWeight;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {

    return Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(border: Border.all(color: borderColor)),
        child: price == 0
            ?
        Text('n/a', style: TextStyle(fontSize: basicFontSize, fontWeight: fontWeight, color: color))
            :
        Text.rich(
            TextSpan(
                children: [
                  TextSpan(
                      text: '€${((price * 100).floor() / 100).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: basicFontSize, fontWeight: fontWeight, color: color)
                  ),
                  TextSpan(
                      text: (price * 1000 % 10).toStringAsFixed(0),
                      style: TextStyle(fontSize: basicFontSize-4, fontWeight: fontWeight, color: color)
                  ),
                ])
        )
    );
  }
}