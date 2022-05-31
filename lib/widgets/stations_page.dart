import 'dart:async';
import 'dart:convert';

import 'package:cfg_flutter/widgets/info_tile.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../model/favorites.dart';
import '../model/fuel_type.dart';
import '../model/price.dart';
import '../model/station.dart';
import '../model/sync_response.dart';
import '../util.dart';
import '../view_mode.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({Key? key, required this.title, required this.viewMode}) : super(key: key);

  final String title;
  final ViewMode viewMode;

  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late FuelType _fuelType = FuelType.petrol95;
  late Favorites _favorites = Favorites.empty();
  SyncResponse? _syncResponse;
  StreamSubscription<LocationData>? _locationStreamSubscription;
  LocationData? _locationData;
  bool showZeros = false;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      int fuelTypeIndex = prefs.getInt(
          CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      final String? favoriteStationCodesRawJson = prefs.getString(
          CyprusFuelGuideApp.keyFavoriteStationCodesRawJson);
      final String? lastRawJson = prefs.getString(
          CyprusFuelGuideApp.keyLastRawJson);
      setState(() {
        _fuelType = FuelType.values[fuelTypeIndex];
        _favorites = favoriteStationCodesRawJson != null ? Favorites.fromJson(
            jsonDecode(favoriteStationCodesRawJson)) : Favorites.empty();
        _syncResponse = SyncResponse.fromRawJson(lastRawJson!);
      });
    });

    Util.requestLocation().then((Location location) {
      _locationStreamSubscription = location.onLocationChanged.listen((LocationData currentLocationData) {
        setState(() => _locationData = currentLocationData);
      });
    });
  }

  @override
  void deactivate() {
    _locationStreamSubscription?.cancel();
    super.deactivate();
  }

  void _saveFavorites() {
    print('*** saving favorites...');
    _prefs.then((SharedPreferences sharedPreferences) {
      String rawJson = jsonEncode(_favorites.toMap());
      sharedPreferences.setString(CyprusFuelGuideApp.keyFavoriteStationCodesRawJson, rawJson);
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
            Expanded(child: _getStationsListView()),
          ],
        )
    );
  }

  ListView _getStationsListView() {

    final Map<String,Price> stationCodeToPrice = {};
    for(final Price price in _syncResponse!.prices) {
      stationCodeToPrice[price.stationCode] = price;
    }
    // filter stations
    final List<Station> selectedStations = [];
    for(final Station station in _syncResponse!.stations) {
      Price? price = stationCodeToPrice[station.code];
      if(widget.viewMode == ViewMode.favorites) {
        if(_favorites.contains(station.code)) {
          selectedStations.add(station);
        }
      } else { // viewMode is ViewMode.cheapest or ViewMode.nearest...
        if((!showZeros && price != null && price.prices[_fuelType.index] > 0)) {
          selectedStations.add(station);
        }
      }
    }
    // sort by price or distance
    if(widget.viewMode == ViewMode.nearest && _locationData != null) { // sort by distance
      double lat = _locationData!.latitude!;
      double lng = _locationData!.longitude!;
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
        return p1 - p2;
      });
    }

    return ListView.separated(
      itemCount: selectedStations.length,
      itemBuilder: (context, index) => _getStationListTile(context, selectedStations[index], stationCodeToPrice[selectedStations[index].code]!),
      separatorBuilder: (context, index) => const Divider(color: Colors.brown),
    );
  }

  ListTile _getStationListTile(BuildContext buildContext, Station station, Price price) {
    String d;
    if(_locationData == null) {
      d = '...';
    } else {
      final double stationDistance = Util.calculateDistanceInMeters(_locationData!.latitude, _locationData!.longitude, station.lat, station.lng);
      d = Util.formatDistance(stationDistance);
    }
    return ListTile(
      leading: Checkbox(
        value: _favorites.contains(station.code),
        checkColor: Colors.green,
        onChanged: (bool? value) => _updateFavorite(station.code),
      ),
      title: Text(station.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d),
          Text('€${(price.prices[_fuelType.index]/1000).toStringAsFixed(3)}'),
          Text(station.address)
        ],
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