import 'dart:async';
import 'dart:convert';

import 'package:cfg_flutter/model/coordinates.dart';
import 'package:cfg_flutter/model/range.dart';
import 'package:cfg_flutter/widgets/distance_view.dart';
import 'package:cfg_flutter/widgets/heart_shape.dart';
import 'package:cfg_flutter/widgets/price_view.dart';
import 'package:flutter/material.dart';
import 'package:greek_tools/greek_tools.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../model/brands.dart';
import '../model/favorites.dart';
import '../model/fuel_type.dart';
import '../model/location_model.dart';
import '../model/price.dart';
import '../model/station.dart';
import '../model/sync_response.dart';
import '../util.dart';
import '../view_mode.dart';
import 'bars_painter.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({Key? key, required this.title, required this.fuelType, required this.viewMode,
    required this.syncResponse, required this.brands, required this.showStatisticsInStationsView, required this.selectedRange}) : super(key: key);

  final String title;
  final FuelType fuelType;
  final ViewMode viewMode;
  final SyncResponse syncResponse;
  final Brands brands;
  final bool showStatisticsInStationsView;
  final Range selectedRange;

  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late int _fuelTypeIndex = 0;
  late FuelType _fuelType = FuelType.petrol95;
  late SyncResponse? _syncResponse = widget.syncResponse;
  late Favorites _favorites = Favorites.empty();
  final bool _showZeros = false;

  @override
  void initState() {
    super.initState();

    _fuelType = widget.fuelType;
    _fuelTypeIndex = _fuelType.index;
    _syncResponse = widget.syncResponse;

    _prefs.then((SharedPreferences prefs) {
      final String? favoriteStationCodesRawJson = prefs.getString(
          CyprusFuelGuideApp.keyFavoriteStationCodesRawJson);
      setState(() {
        _fuelType = FuelType.values[_fuelTypeIndex];
        _favorites = favoriteStationCodesRawJson != null ? Favorites.fromJson(
            jsonDecode(favoriteStationCodesRawJson)) : Favorites.empty();
      });
    });
  }

  void _saveFavorites() {
    _prefs.then((SharedPreferences sharedPreferences) {
      String rawJson = jsonEncode(_favorites.toMap());
      sharedPreferences.setString(CyprusFuelGuideApp.keyFavoriteStationCodesRawJson, rawJson);
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<int,int> priceCounts = {};
    for (Price price in _syncResponse!.prices) {
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

    return Column(
      children: [
        Expanded(
            child: _syncResponse == null
                ?
            const Center(child: Text('No data'))
                :
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // InfoTileWidget(label: label),
                widget.showStatisticsInStationsView ?
                SizedBox(
                  height: 100,
                  child: CustomPaint(painter: BarsPainter(values: priceCounts, absMin: absMin, absMax: absMax)),
                )
                    :
                Container(),
                Container(height: 1, color: Colors.brown),
                Expanded(child: Consumer<LocationModel>(
                    builder: (context, locationModel, child) {
                      return _getStationsListView(locationModel.coordinates);
                    }
                )),
              ],
            )
        ),
      ],
    );
  }

  ListView _getStationsListView(Coordinates coordinates) {

    final Map<String,Price> stationCodeToPrice = {};
    for(final Price price in _syncResponse!.prices) {
      stationCodeToPrice[price.stationCode] = price;
    }
    // filter stations
    double lat = coordinates.latitude;
    double lng = coordinates.longitude;
    final double rangeInMeters = widget.selectedRange.value * 1000;
    final List<Station> selectedStations = [];
    for(final Station station in _syncResponse!.stations) {
      // filter stations by brands (except in favorites)
      final bool stationBrandIsSelected = widget.brands.isEmpty() || widget.brands.isChecked(station.brand); // is empty, do not filter
      Price? price = stationCodeToPrice[station.code];
      if(widget.viewMode == ViewMode.favorites) {
        if (_favorites.contains(station.code)) {
          selectedStations.add(station);
        }
      } else if(widget.viewMode == ViewMode.bestValue) { // limit by distance < range
        double distance = Util.calculateDistanceInMeters(lat, lng, station.lat, station.lng);
        if(distance <= rangeInMeters && !_showZeros && price != null && price.prices[_fuelType.index] > 0 && stationBrandIsSelected) {
          selectedStations.add(station);
        }
      } else { // viewMode is ViewMode.cheapest or ViewMode.nearest...
        if(!_showZeros && price != null && price.prices[_fuelType.index] > 0 && stationBrandIsSelected) {
          selectedStations.add(station);
        }
      }
    }

    // sort by price or distance
    if(widget.viewMode == ViewMode.nearest) { // sort by distance
      double lat = coordinates.latitude;
      double lng = coordinates.longitude;
      selectedStations.sort((s1, s2) {
        double d1 = Util.calculateDistanceInMeters(lat, lng, s1.lat, s1.lng);
        double d2 = Util.calculateDistanceInMeters(lat, lng, s2.lat, s2.lng);
        return (d1 - d2).round();
      });
    } else { // sort by price
      selectedStations.sort((s1, s2) {
        Price? price1 = stationCodeToPrice[s1.code];
        Price? price2 = stationCodeToPrice[s2.code];
        int p1 = price1 != null ? price1.prices[_fuelType.index] : 0;
        int p2 = price2 != null ? price2.prices[_fuelType.index] : 0;
        if(p1 == 0) return 1;
        if(p2 == 0) return -1;
        return p1 - p2;
      });
    }

    if(widget.viewMode == ViewMode.favorites && selectedStations.isEmpty) {
      return ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.block),
            title: Text('No favorites found'),
            subtitle: Text('You can select any stations as favorite from the other views'),
          ),
        ],
      );
    }

    if(widget.viewMode == ViewMode.bestValue && selectedStations.isEmpty) {
      return ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.block),
            title: Text('No stations found within the range'),
            subtitle: Text('You can increase the range in the settings or select another view'),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: selectedStations.length,
      itemBuilder: (context, index) => _getStationListTile(context, selectedStations[index], stationCodeToPrice[selectedStations[index].code]!, coordinates),
      separatorBuilder: (context, index) => const Divider(color: Colors.brown),
    );
  }

  ListTile _getStationListTile(BuildContext buildContext, Station station, Price price, Coordinates coordinates) {
    double d;
    double p = price.prices[_fuelType.index] / 1000;
    d = Util.calculateDistanceInMeters(coordinates.latitude, coordinates.longitude, station.lat, station.lng);
    return ListTile(
      leading: Checkbox(
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // shape: const StarShape(),
        shape: const HeartShape(),
        checkColor: Colors.transparent,
        value: _favorites.contains(station.code),
        activeColor: Colors.brown,
        onChanged: (bool? value) => _updateFavorite(station.code),
      ),
      title: Row(
        children: [
          PriceView(price: p, basicFontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
          const Padding(padding: EdgeInsets.all(4), child: Text('@', style: TextStyle(fontSize: 10, color: Colors.brown))),
          Flexible(
              child: Text(toGreeklish(station.name), style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis))
        ],
      ),
      subtitle: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Row(
            children: [
              DistanceView(distanceInMeters: d, fontSize: 16, color: Colors.brown, fontWeight: FontWeight.bold),
              Flexible(
                child: Text(' ~ ${toGreeklish(station.address)}', overflow: TextOverflow.ellipsis),
              )
            ],
          )
      ),
      trailing: Util.imageForBrand(station.brand),
      onTap: () => CyprusFuelGuideApp.router.navigateTo(context, '/station/${station.code}'),
    );
  }

  void _updateFavorite(String stationCode) {
    setState(() {
      if (_favorites.contains(stationCode)) {
        _favorites.remove(stationCode);
      } else {
        _favorites.add(stationCode);
      }
    });
    _saveFavorites();
  }
}