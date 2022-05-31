import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../model/fuel_type.dart';
import '../model/sync_response.dart';
import '../view_mode.dart';
import 'info_tile.dart';

class TrendsPage extends StatefulWidget {

  const TrendsPage({Key? key, required this.title, required this.viewMode}) : super(key: key);

  final String title;
  final ViewMode viewMode;

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late FuelType _fuelType = FuelType.petrol95;
  SyncResponse? _syncResponse;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      int fuelTypeIndex = prefs.getInt(
          CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      final String? lastRawJson = prefs.getString(
          CyprusFuelGuideApp.keyLastRawJson);
      setState(() {
        _fuelType = FuelType.values[fuelTypeIndex];
        _syncResponse = SyncResponse.fromRawJson(lastRawJson!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: _syncResponse == null
            ?
        const Center(child: Text('No data'))
            :
        Column(
          children: [
            InfoTileWidget(fuelType: _fuelType, viewMode: widget.viewMode),
            Expanded(child: Text('todo')),//todo
          ],
        )
    );
  }
}