import 'dart:async';
import 'dart:convert';

import 'package:cfg_flutter/model/favorites.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:cfg_flutter/widgets/fuel_type_statistics.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../model/fuel_type.dart';
import '../model/price.dart';
import '../model/station.dart';
import '../util.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key, required this.fuelType, required this.syncResponse}) : super(key: key);

  final FuelType fuelType;
  final SyncResponse? syncResponse;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late FuelType _fuelType = FuelType.petrol95;
  late Favorites _favorites = Favorites.empty();
  Location location = Location();
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      int fuelTypeIndex = prefs.getInt(
          CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      setState(() {
        _fuelType = FuelType.values[fuelTypeIndex];
      });
    });

    _loadFavorites();

    location.getLocation().then((LocationData locationData) {
      setState(() => _locationData = locationData);
    });
  }

  void _loadFavorites() {
    _prefs.then((SharedPreferences prefs) {
      final String? favoriteStationCodesRawJson = prefs.getString(
          CyprusFuelGuideApp.keyFavoriteStationCodesRawJson);
      setState(() {
        _favorites = favoriteStationCodesRawJson != null ? Favorites.fromJson(
            jsonDecode(favoriteStationCodesRawJson)) : Favorites.empty();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.syncResponse == null
        ?
    const Text('No data')
        :
    _getListView(widget.syncResponse!, widget.fuelType);
  }

  Widget _getListView(SyncResponse syncResponse, FuelType fuelType) {
    FuelTypeStatistics fuelTypeStatistics = FuelTypeStatistics.from(syncResponse, fuelType);
    final int numOfStations = syncResponse.stations.length;
    final int minPrice = fuelTypeStatistics.minPrice;
    final double avgPrice = fuelTypeStatistics.averagePrice;
    final int diff = (avgPrice - minPrice).round();
    final int numOfBestPriceStations = fuelTypeStatistics.pricesToStationCodes[minPrice]!.length;
    Map<String,int> stationCodesToPrice = {};
    for(final Price price in syncResponse.prices) {
      stationCodesToPrice[price.stationCode] = price.prices[fuelType.index];
    }
    Map<Station,double> stationsToDistance = {};
    double nearestStationDistance = double.maxFinite;
    int? nearestStationPrice = 0;
    if(_locationData != null) {
      double lat = _locationData!.latitude!;
      double lng = _locationData!.longitude!;
      for (Station station in syncResponse.stations) {
        double stationDistance = Util.calculateDistanceInMeters(lat, lng, station.lat, station.lng);
        stationsToDistance[station] = stationDistance;
        if(stationDistance < nearestStationDistance) {
          nearestStationDistance = stationDistance;
          nearestStationPrice = stationCodesToPrice[station.code];
        }
      }
    }
    // compute best price among favorites
    int bestPrice = fuelTypeStatistics.maxPrice;
    syncResponse.prices.forEach((Price price) {
      if(_favorites.contains(price.stationCode)) {
        if(price.prices[_fuelType.index] < bestPrice) {
          bestPrice = price.prices[_fuelType.index];
        }
      }
    });

    return ListView(
      children: [
        // best price cards
        _getCard(const Icon(Icons.check, color: Colors.green), 'Best price €${(minPrice/1000).toStringAsFixed(3)} in $numOfStations stations', 'This is ${diff/10}¢ cheaper than the average, available in $numOfBestPriceStations station${numOfBestPriceStations > 1 ? "s" : ""}', _navToStationsByPrice),
        // check location
        _locationData == null
            ?
        _getUnknownLocationCard()
            :
        _getCard(const Icon(Icons.near_me_outlined, color: Colors.green), 'Nearest station ${Util.formatDistance(nearestStationDistance)} away', 'Prices from €${nearestStationPrice!/1000}', _navToStationsByDistance),
        // check favorites
        _favorites.isEmpty()
            ?
        _getNoFavoritesCard()
            :
        _getCard(const Icon(Icons.check_box_outlined, color: Colors.green), 'Best price €${(bestPrice/1000).toStringAsFixed(3)} in favorites', 'Comparing prices from ${_favorites.length()} favorites', _navToFavoriteStations),//todo
        // stats
        _getCard(const Icon(Icons.stacked_line_chart_outlined, color: Colors.green), 'Trends', 'Trends in prices', _navToStationsByPrice),
      ],
    );
  }

  Widget _getCard(Widget icon, String title, String subtitle, Function callback) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: Card(
            elevation: 4,
            child: InkWell(
              onTap: () => callback(),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(width: 5),
                      icon,
                      Container(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Theme.of(context).textTheme.titleMedium),
                            Container(height: 12),
                            Text(subtitle, style: Theme.of(context).textTheme.caption),
                          ],
                        ),
                      )
                    ],
                  )
              ),
            )
        )
    );
  }

  Widget _getUnknownLocationCard() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: Card(
            elevation: 4,
            child: InkWell(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(width: 5),
                      const Icon(Icons.near_me_outlined, color: Colors.grey),
                      Container(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unknown location', style: Theme.of(context).textTheme.titleMedium),
                            Container(height: 12),
                            Text('Make sure your location service is turned on', style: Theme.of(context).textTheme.caption),
                          ],
                        ),
                      )
                    ],
                  )
              ),
            )
        )
    );
  }

  Widget _getNoFavoritesCard() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: Card(
            elevation: 4,
            child: InkWell(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(width: 5),
                      const Icon(Icons.check_box_outlined, color: Colors.grey),
                      Container(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No favorites selected', style: Theme.of(context).textTheme.titleMedium),
                            Container(height: 12),
                            Text('Check any stations to mark as favorite', style: Theme.of(context).textTheme.caption),
                          ],
                        ),
                      )
                    ],
                  )
              ),
            )
        )
    );
  }

  void _navToStationsByPrice() async {
    CyprusFuelGuideApp.router.navigateTo(context, '/stationsByPrice').then((_) => _loadFavorites());
  }

  void _navToStationsByDistance() async {
    CyprusFuelGuideApp.router.navigateTo(context, '/stationsByDistance').then((_) => _loadFavorites());
  }

  void _navToFavoriteStations() async {
    CyprusFuelGuideApp.router.navigateTo(context, '/favoriteStations').then((_) => _loadFavorites());
  }
}