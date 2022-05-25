import 'package:flutter/material.dart';

class CfgDrawerHeader extends StatelessWidget {
  const CfgDrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.amber,
                Colors.amberAccent,
              ]
          ),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Image(image: AssetImage('icons/launcher.png'), height: 100,),
              Text('Cyprus Fuel Guide', style: Theme.of(context).textTheme.headline6),
            ]
        )
    );
  }
}