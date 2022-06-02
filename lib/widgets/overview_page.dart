import 'dart:async';
import 'dart:convert';

import 'package:cfg_flutter/model/favorites.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:cfg_flutter/widgets/fuel_type_statistics.dart';
import 'package:cfg_flutter/widgets/no_favorites_card.dart';
import 'package:cfg_flutter/widgets/unknown_location_card.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../model/fuel_type.dart';
import '../model/price.dart';
import '../model/station.dart';
import '../util.dart';

class Overview extends StatefulWidget {
  const Overview({Key? key, required this.syncResponse}) : super(key: key);

  final SyncResponse? syncResponse;

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late FuelType _fuelType = FuelType.petrol95;
  late Favorites _favorites = Favorites.empty();
  Location location = Location();
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();

    _loadFromPreferences();

    location.getLocation().then((LocationData locationData) {
      setState(() => _locationData = locationData);
    });
  }

  void _loadFromPreferences() {
    _prefs.then((SharedPreferences prefs) {
      int fuelTypeIndex = prefs.getInt(
          CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      final String? favoriteStationCodesRawJson = prefs.getString(
          CyprusFuelGuideApp.keyFavoriteStationCodesRawJson);
      setState(() {
        _fuelType = FuelType.values[fuelTypeIndex];
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
    _getListView(widget.syncResponse!, _fuelType);
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
    for (final Price price in syncResponse.prices) {
      if(_favorites.contains(price.stationCode)) {
        if(price.prices[_fuelType.index] < bestPrice && price.prices[_fuelType.index] > 0) {
          bestPrice = price.prices[_fuelType.index];
        }
      }
    }

    return ListView(
      children: [
        // best price cards
        _getCard(const Icon(Icons.euro_outlined, color: Colors.green), 'Best price €${(minPrice/1000).toStringAsFixed(3)} in $numOfStations stations', 'This is ${diff/10}¢ cheaper than the average, available in $numOfBestPriceStations station${numOfBestPriceStations > 1 ? "s" : ""}', _navToStationsByPrice),
        // check location
        _locationData == null
            ?
        const UnknownLocationCard()
            :
        _getCard(const Icon(Icons.near_me_outlined, color: Colors.green), 'Nearest station ${Util.formatDistance(nearestStationDistance)} away', 'Prices from €${nearestStationPrice!/1000}', _navToStationsByDistance),
        // check favorites
        _favorites.isEmpty()
            ?
        const NoFavoritesCard()
            :
        _getCard(const Icon(Icons.check_box_outlined, color: Colors.green), 'Best price €${(bestPrice/1000).toStringAsFixed(3)} in favorites', 'Comparing prices from ${_favorites.length()} favorite${_favorites.length() > 2 ? 's' : ''}', _navToFavoriteStations),
        // stats
        _getCard(const Icon(Icons.stacked_line_chart_outlined, color: Colors.green), 'Trends', 'Trends in prices', _navToTrendsPage),
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

  void _navToStationsByPrice() async {
    CyprusFuelGuideApp.router.navigateTo(context, '/stationsByPrice').then((_) => _loadFromPreferences());
  }

  void _navToStationsByDistance() async {
    CyprusFuelGuideApp.router.navigateTo(context, '/stationsByDistance').then((_) => _loadFromPreferences());
  }

  void _navToFavoriteStations() async {
    CyprusFuelGuideApp.router.navigateTo(context, '/favoriteStations').then((_) => _loadFromPreferences());
  }

  void _navToTrendsPage() async {
    CyprusFuelGuideApp.router.navigateTo(context, '/trends');
  }
}