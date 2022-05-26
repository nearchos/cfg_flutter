import 'package:cfg_flutter/model/sync_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../model/price.dart';
import '../model/station.dart';

class StationPage extends StatefulWidget {
  const StationPage({Key? key, required this.title, required this.code}) : super(key: key);

  final String title;
  final String code; // station code

  @override
  State<StationPage> createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Station? _station;
  Price? _price;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      final String? lastRawJson = prefs.getString(CyprusFuelGuideApp.keyLastRawJson);
      final SyncResponse syncResponse = SyncResponse.fromRawJson(lastRawJson!);
      List<Station> stations = syncResponse.stations;
      List<Price> prices = syncResponse.prices;
      setState(() {
        _station = stations.firstWhere((s) => s.code == widget.code);
        _price = prices.firstWhere((p) => p.stationCode == widget.code);
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
        body:
        _station == null || _price == null ?
        const LinearProgressIndicator()
            :
        _getStationView()
    );
  }

  Column _getStationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Station ... ${_station!.toString()}'),
        Text('Prices ... ${_price!.toString()}'),
      ],
    );
  }
}