import 'package:flutter/material.dart';

class ShortDrawerHeader extends StatelessWidget {
  const ShortDrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
        padding: EdgeInsets.fromLTRB(16.0, statusBarHeight + 16.0, 16.0, 16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.amber,
                Colors.amberAccent,
              ]
          ),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Image(image: AssetImage('icons/launcher.png'), height: 50,),
              const SizedBox(width: 10,),
              Text('Cyprus Fuel Guide', style: Theme.of(context).textTheme.headline6),
            ]
        )
    );
  }
}