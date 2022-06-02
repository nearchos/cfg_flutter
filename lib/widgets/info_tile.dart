import 'package:flutter/material.dart';

class InfoTileWidget extends StatelessWidget {
  const InfoTileWidget({Key? key, required this.label}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: SizedBox(
        height: 32,
        child: Center(
            child: Text(label, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))
        ),
      ),
    );
  }
}