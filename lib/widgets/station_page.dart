import 'package:flutter/material.dart';

import '../model/station.dart';

class StationPage extends StatefulWidget {
  const StationPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StationPage> createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> {

  @override
  Widget build(BuildContext context) {
    debugPrint('build station ...');
    return MaterialApp(
      onGenerateRoute: (settings) {
        debugPrint('args: >>${settings.name}<<');
      },
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            leading: IconButton(icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(false)),
          ),
          body: ListView(
              children: [
              Text('Station ...')
      ],
    )
    )
    );
  }
}