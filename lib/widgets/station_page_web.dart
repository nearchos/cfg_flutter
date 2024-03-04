import 'dart:async';
import 'dart:ui' as ui;

import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:cfg_flutter/widgets/distance_view.dart';
import 'package:cfg_flutter/widgets/price_view.dart';
import 'package:flutter/material.dart';
import 'package:greek_tools/greek_tools.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps/google_maps.dart' as g_maps;
import 'package:universal_html/html.dart' as html;
import 'package:web/src/dom/html.dart' show HTMLElement;

import '../main.dart';
import '../model/coordinates.dart';
import '../model/location_model.dart';
import '../model/price.dart';
import '../model/station.dart';
import '../util.dart';
import 'bars_painter.dart';

class StationPage extends StatefulWidget {
  const StationPage({super.key, required this.code});

  final String code; // station code
  final double fontSize = 13;

  @override
  State<StationPage> createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> {

  final int zoomLevel = 16;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Station? _station;
  Price? _price;
  FuelType _fuelType = FuelType.petrol95;
  int _fuelTypeIndex = 0;
  String _title = 'Station';
  bool _showInGreek = false;

  @override
  void setState(VoidCallback fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  late List<Station> _stations;
  late List<Price> _prices;

  late bool _showStatisticsInStationView = true;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      final String? lastRawJson = prefs.getString(CyprusFuelGuideApp.keyLastRawJson);
      final SyncResponse syncResponse = SyncResponse.fromRawJson(lastRawJson!);
      _stations = syncResponse.stations;
      _prices = syncResponse.prices;
      _fuelTypeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      bool showInGreek = prefs.getBool(CyprusFuelGuideApp.keyShowInGreek) ?? false;
      bool showStatisticsInStationView = prefs.getBool(CyprusFuelGuideApp.keyShowStatisticsInStationView) ?? true;

      setState(() {
        _station = _stations.firstWhere((s) => s.code == widget.code);
        _price = _prices.firstWhere((p) => p.stationCode == widget.code);
        _title = _station!.name;
        _fuelType = FuelType.values[_fuelTypeIndex];
        _showInGreek = showInGreek;
        _showStatisticsInStationView = showStatisticsInStationView;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(false)),
      ),
      body: _station == null || _price == null
          ?
      const LinearProgressIndicator()
          :
      _getStationView(widget.fontSize),
    );
  }

  Widget _getStationView(final double fontSize) {

    Map<int,int> priceCounts = {};
    for (Price price in _prices) {
      int p = price.prices[_fuelTypeIndex];
      if(p == 0) continue; // ignore zeros for price - they usually mean the station doesn't have that fuel type
      if(!priceCounts.containsKey(p)) {
        priceCounts[p] = 0;
      }
      priceCounts[p] = priceCounts[p]! + 1;
    }
    List<int> prices = priceCounts.keys.toList();
    prices.sort();
    int absMin = prices.first;
    int absMax = prices.last;

    int price = _price!.prices[_fuelTypeIndex];
    int cheaperThan = 0;
    int rank = 1;
    for(int p in prices) {
      if(price < p) {
        cheaperThan += priceCounts[p]!;
      } else if(price > p) {
        rank += priceCounts[p]!;
      }
    }
    String message;
    if(price == absMin) {
      message = 'This station is ranked #$rank and is among the cheapest in Cyprus. It is ${(absMax - absMin) / 10}¢ cheaper than the most expensive station.';
    } else if(price == absMax) {
      message = 'This station is ranked #$rank and is one of the most expensive in Cyprus. It is ${(absMax - absMin) / 10}¢ more expensive than the cheapest station.';
    } else {
      message = 'This station is ranked #$rank and is cheaper than $cheaperThan stations. It is ${(price - absMin) / 10}¢ more expensive than the cheapest.';
    }

    String htmlId = "myMapId";

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(htmlId, (int viewId) {
      final myLatLng = g_maps.LatLng(_station!.lat, _station!.lng);

      final mapOptions = g_maps.MapOptions()
        ..zoom = zoomLevel
        ..center = g_maps.LatLng(_station!.lat, _station!.lng);

      final elem = html.DivElement()
        ..id = htmlId
        ..style.width = "100%"
        ..style.height = "100%"
        ..style.border = 'none';

      final map = g_maps.GMap(elem as HTMLElement?, mapOptions);

      g_maps.Marker(g_maps.MarkerOptions()
        ..position = myLatLng
        ..map = map
        ..title = _station!.name
      );

      return elem;
    });

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getFuelBox(FuelType.petrol95, _price!.prices[FuelType.petrol95.index], _fuelType==FuelType.petrol95),
                  _getFuelBox(FuelType.petrol98, _price!.prices[FuelType.petrol98.index], _fuelType==FuelType.petrol98),
                  _getFuelBox(FuelType.diesel, _price!.prices[FuelType.diesel.index], _fuelType==FuelType.diesel),
                  _getFuelBox(FuelType.heating, _price!.prices[FuelType.heating.index], _fuelType==FuelType.heating),
                  _getFuelBox(FuelType.kerosene, _price!.prices[FuelType.kerosene.index], _fuelType==FuelType.kerosene),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.amberAccent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _showStatisticsInStationView ?
                    SizedBox(
                      height: 100,
                      child: CustomPaint(painter: BarsPainter(values: priceCounts, absMin: absMin, absMax: absMax, selectedStationPrice: _price!.prices[_fuelTypeIndex])),
                    )
                        :
                    Container(),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(message, style: TextStyle(fontSize: fontSize, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.brown),
              Expanded(
                  child: HtmlElementView(viewType: htmlId)
              ),
              Container(height: 1, color: Colors.brown),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Consumer<LocationModel>(
                            builder: (context, locationModel, child) {
                              Coordinates coordinates = locationModel.coordinates;
                              double distanceInMeters = Util.calculateDistanceInMeters(coordinates.latitude, coordinates.longitude, _station!.lat, _station!.lng);
                              return SizedBox(width: 64, child: DistanceView(distanceInMeters: distanceInMeters, fontSize: 20));
                            }
                        ),
                      ),
                      Expanded(
                          child:  Text('${_showInGreek ? _station!.address : toGreeklish(_station!.address)}\n'
                              '${_showInGreek ? _station!.district : toGreeklish(_station!.district)}, ${_showInGreek ? _station!.city : toGreeklish(_station!.city)}', textAlign: TextAlign.end,)
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _navigate,
                        child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.navigation, color: Colors.brown)),
                      )
                    ]
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(width: 64, child: Util.imageForBrand(_station!.brand)),
                      ),
                      Expanded(child: Text('${_showInGreek ? _station!.name : toGreeklish(_station!.name)}\n'
                          'tel. ${_station!.telNo}', textAlign: TextAlign.end)),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _call,
                        child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.call, color: Colors.brown)),
                      )
                    ]
                ),
              ),
            ],
          )
      ),
    );
  }

  Widget _getFuelBox(final FuelType fuelType, final int priceInMillieuro, bool selected) {
    return Expanded(
        child: Container(
          color: selected ? Colors.amberAccent : Colors.white10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(fuelType.name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              PriceView(price: priceInMillieuro/1000, fontWeight: selected ? FontWeight.bold : FontWeight.normal)
            ],
          ),
        )
    );
  }

  void _call() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: _station!.telNo,
    );
    await launchUrl(launchUri);
  }

  void _navigate() async {
    _launchMapsUrlWeb('${_station!.name}, ${_station!.address}', _station!.lat, _station!.lng);
  }

  _launchMapsUrlWeb(String title, double lat, double lon) async {
    final Uri launchUri = Uri(
        scheme: 'https',
        host: 'maps.google.com',
        path: 'maps',
        query: 'z=$zoomLevel&t=m&q=loc:$lat+$lon'
    );
    await launchUrl(launchUri);
  }
}