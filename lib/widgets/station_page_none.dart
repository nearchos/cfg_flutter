import 'package:flutter/widgets.dart';

class StationPage extends StatelessWidget {
  const StationPage({Key? key, required this.code}) : super(key: key);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Text('Station page not implemented for this platform [code: $code]');
  }
}