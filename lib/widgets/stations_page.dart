import 'dart:async';
import 'dart:io' as io;
import 'dart:convert';

import 'package:cfg_flutter/widgets/distance_view.dart';
import 'package:cfg_flutter/widgets/info_tile.dart';
import 'package:cfg_flutter/widgets/price_view.dart';
import 'package:cfg_flutter/widgets/star_shape.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:greek_tools/greek_tools.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../keys.dart';
import '../main.dart';
import '../model/favorites.dart';
import '../model/fuel_type.dart';
import '../model/location_model.dart';
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

  Future<void> _createAnchoredBanner(BuildContext context) async {
    final AnchoredAdaptiveBannerAdSize? size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      // print('Unable to get height of anchored banner.');
      return;
    }

    final BannerAd banner = BannerAd(
      size: size,
      request: const AdRequest(),
      adUnitId: io.Platform.isAndroid ? adUnitIdAndroid : adUnitIdIOS,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          // print('$BannerAd loaded.');
          setState(() {
            _anchoredBanner = ad as BannerAd?;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    );
    return banner.load();
  }

  BannerAd? _anchoredBanner;
  bool _loadingAnchoredBanner = false;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late FuelType _fuelType = FuelType.petrol95;
  late Favorites _favorites = Favorites.empty();
  SyncResponse? _syncResponse;
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
  }

  void _saveFavorites() {
    _prefs.then((SharedPreferences sharedPreferences) {
      String rawJson = jsonEncode(_favorites.toMap());
      sharedPreferences.setString(CyprusFuelGuideApp.keyFavoriteStationCodesRawJson, rawJson);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadingAnchoredBanner) {
      _loadingAnchoredBanner = true;
    }
    _createAnchoredBanner(context);

    String label = ' ⛽ ';
    switch(widget.viewMode) {
      case ViewMode.overview: label += 'Overview'; break;
      case ViewMode.cheapest: label += 'Cheapest'; break;
      case ViewMode.nearest: label += 'Nearest'; break;
      case ViewMode.favorites: label += 'Favorites'; break;
    }
    label += ' · ';
    switch(_fuelType) {
      case FuelType.petrol95: label += 'Unleaded Petrol 95'; break;
      case FuelType.petrol98: label += 'Unleaded Petrol 98'; break;
      case FuelType.diesel: label += 'Diesel'; break;
      case FuelType.heating: label += 'Heating'; break;
      case FuelType.kerosene: label += 'Kerosene'; break;
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: Column(
          children: [
            Expanded(
                child: _syncResponse == null
                    ?
                const Center(child: Text('No data'))
                    :
                Column(
                  children: [
                    InfoTileWidget(label: label),
                    Expanded(child: Consumer<LocationModel>(
                        builder: (context, locationModel, child) {
                          return _getStationsListView(locationModel.locationData);
                        }
                    )),
                  ],
                )
            ),

            // show ad banner
            _anchoredBanner == null
                ?
            Container() // empty if no ads
                :
            Container(
              color: Colors.amber,
              alignment: Alignment.center,
              width: _anchoredBanner!.size.width.toDouble(),
              height: _anchoredBanner!.size.height.toDouble(),
              child: AdWidget(ad: _anchoredBanner!),
            ) // shows ads only on Web
          ],
        )
    );
  }

  ListView _getStationsListView(LocationData? locationData) {

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
    if(widget.viewMode == ViewMode.nearest && locationData != null) { // sort by distance
      double lat = locationData.latitude!;
      double lng = locationData.longitude!;
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

    return ListView.separated(
      itemCount: selectedStations.length,
      itemBuilder: (context, index) => _getStationListTile(context, selectedStations[index], stationCodeToPrice[selectedStations[index].code]!, locationData),
      separatorBuilder: (context, index) => const Divider(color: Colors.brown),
    );
  }

  ListTile _getStationListTile(BuildContext buildContext, Station station, Price price, LocationData? locationData) {
    double d;
    double p = price.prices[_fuelType.index] / 1000;
    if(locationData == null) {
      d = double.infinity;
    } else {
      d = Util.calculateDistanceInMeters(locationData.latitude, locationData.longitude, station.lat, station.lng);
    }
    return ListTile(
      leading: Checkbox(
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shape: const StarShape(),
        checkColor: Colors.transparent,
        value: _favorites.contains(station.code),
        activeColor: Colors.green,
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