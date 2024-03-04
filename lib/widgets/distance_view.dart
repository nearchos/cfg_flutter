import 'package:flutter/material.dart';

class DistanceView extends StatelessWidget {

  const DistanceView({Key? key, required this.distanceInMeters, this.fontSize = 18, this.fontWeight = FontWeight.normal, this.color = Colors.black}) : super(key: key);

  final double distanceInMeters;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  @override
  Widget build(BuildContext context) {

    return distanceInMeters == double.infinity
        ?
    const Text('..?') // todo
        :
    distanceInMeters > 99999 // > 99Km
        ?
    Text.rich(
        TextSpan(
            children: [
              TextSpan(
                  text: '>99',
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color)
              ),
              TextSpan(
                  text: 'Km',
                  style: TextStyle(fontSize: fontSize-4, fontWeight: fontWeight, color: color)
              ),
            ])
    )
        :
    distanceInMeters > 1000 // 1..99Km
        ?
    Text.rich(
        TextSpan(
            children: [
              TextSpan(
                  text: (distanceInMeters/1000).toStringAsFixed(1),
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color)
              ),
              TextSpan(
                  text: 'Km',
                  style: TextStyle(fontSize: fontSize-4, fontWeight: fontWeight, color: color)
              ),
            ])
    )
        :
    Text.rich(
        TextSpan(
            children: [
              TextSpan(
                  text: (distanceInMeters~/10*10).toStringAsFixed(0),
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color)
              ),
              TextSpan(
                  text: 'm',
                  style: TextStyle(fontSize: fontSize-4, fontWeight: fontWeight, color: color)
              ),
            ])
    );
  }
}