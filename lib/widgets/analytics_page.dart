import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:greek_tools/greek_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../keys.dart';
import '../main.dart';
import '../model/fuel_type.dart';
import '../model/price.dart';
import '../model/station.dart';
import '../model/sync_response.dart';
import 'bars_painter.dart';
import 'info_tile.dart';

class AnalyticsPage extends StatefulWidget {

  const AnalyticsPage({super.key, required this.title});

  final String title;
  final double fontSize = 13;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

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
  late int _fuelTypeIndex = 0;
  SyncResponse? _syncResponse;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      _fuelTypeIndex = prefs.getInt(
          CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      final String? lastRawJson = prefs.getString(
          CyprusFuelGuideApp.keyLastRawJson);
      setState(() {
        _fuelType = FuelType.values[_fuelTypeIndex];
        _syncResponse = SyncResponse.fromRawJson(lastRawJson!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadingAnchoredBanner) {
      _loadingAnchoredBanner = true;
    }
    _createAnchoredBanner(context);

    String label = ' ⛽ Analytics · ';
    switch(_fuelType) {
      case FuelType.petrol95: label += 'Unleaded Petrol 95'; break;
      case FuelType.petrol98: label += 'Unleaded Petrol 98'; break;
      case FuelType.diesel: label += 'Diesel'; break;
      case FuelType.heating: label += 'Heating'; break;
      case FuelType.kerosene: label += 'Kerosene'; break;
    }

    String country = "Cyprus";
    Map<String,int> citiesToCountsOfStations = {country: 0};
    Map<String,int> citiesToSumsOfPrices = {country: 0};
    Map<String,int> citiesToMinPrice = {country: 0x7fffffff}; // initially, max 32-bit int value
    Map<String,int> citiesToMaxPrice = {country: 0}; // initially, min int value
    Map<String,Map<int,int>> citiesToPriceCounts = {country: {}};
    Map<String,Station> stationCodesToStations = {};
    if(_syncResponse != null) {
      for(Station station in _syncResponse!.stations) {
        // count stations in each city
        if(!citiesToCountsOfStations.containsKey(station.city)) {
          citiesToCountsOfStations[station.city] = 0;
          citiesToSumsOfPrices[station.city] = 0;
          citiesToMinPrice[station.city] = 0x7fffffff; // initially, max 32-bit int value
          citiesToMaxPrice[station.city] = 0; // initially, min int value
          citiesToPriceCounts[station.city] = {};
        }
        citiesToCountsOfStations[station.city] = citiesToCountsOfStations[station.city]! + 1;
        citiesToCountsOfStations[country] = citiesToCountsOfStations[country]! + 1;
        stationCodesToStations[station.code] = station;
      }
      for (Price price in _syncResponse!.prices) {
        String c = stationCodesToStations[price.stationCode]!.city;
        int p = price.prices[_fuelTypeIndex];
        if(p == 0) continue; // ignore zeros for price - they usually mean the station doesn't have that fuel type
        citiesToSumsOfPrices[c] = citiesToSumsOfPrices[c]! + p;
        citiesToSumsOfPrices[country] = citiesToSumsOfPrices[country]! + p;
        if(p < citiesToMinPrice[c]!) {
          citiesToMinPrice[c] = p;
          if(p < citiesToMinPrice[country]!) { citiesToMinPrice[country] = p; }
        }
        if(p > citiesToMaxPrice[c]!) {
          citiesToMaxPrice[c] = p;
          if(p > citiesToMaxPrice[country]!) { citiesToMaxPrice[country] = p; }
        }
        Map<int,int> priceCounts = citiesToPriceCounts[c]!;
        if(!priceCounts.containsKey(p)) {
          priceCounts[p] = 0;
        }
        priceCounts[p] = priceCounts[p]! + 1;
        citiesToPriceCounts[c] = priceCounts;

        Map<int,int> priceCountryCounts = citiesToPriceCounts[country]!;
        if(!priceCountryCounts.containsKey(p)) {
          priceCountryCounts[p] = 0;
        }
        priceCountryCounts[p] = priceCountryCounts[p]! + 1;
        citiesToPriceCounts[country] = priceCountryCounts;
      }
    }

    List<String> cities = citiesToCountsOfStations.keys.toList();
    cities.sort((city1, city2) => citiesToCountsOfStations[city2]! - citiesToCountsOfStations[city1]!);
    List<Widget> cards = cities
        .map((city) => getFrequencyChart(city, citiesToCountsOfStations, citiesToPriceCounts[city]!, citiesToMinPrice[country]!, citiesToMaxPrice[country]!))
        .toList();

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
            InfoTileWidget(label: label),
            Expanded(
              child: _syncResponse == null
                  ?
              const CircularProgressIndicator()
                  :
              ListView(children: cards),
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

  Widget getFrequencyChart(String city, Map<String,int> citiesToCountsOfStations, Map<int,int> priceCounts, int absMin, int absMax) {
    List<int> keys = priceCounts.keys.toList();
    keys.sort();
    List<int> allPrices = [];
    for(int key in keys) {
      int numOfStationsWithPrice = priceCounts[key]!;
      for(int i = 0; i < numOfStationsWithPrice; i++) {
        allPrices.add(key);
      }
    }
    int min = allPrices.first;
    int max = allPrices.last;
    int quartileStart = allPrices[allPrices.length ~/ 4];
    int quartileEnd = allPrices[3 * allPrices.length ~/ 4];
    int median = allPrices.median();
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Card(
            elevation: 4,
            child: InkWell(
              onTap: null,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(toGreeklish(city.capitalize())),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: const ShapeDecoration(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))),
                        child: SizedBox(
                            height: 100,
                            child: CustomPaint(painter: BarsPainter(values: priceCounts, absMin: absMin, absMax: absMax))),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: const Text('Details', style: TextStyle(fontSize: 12, color: Colors.black87)),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        expandedAlignment: Alignment.centerLeft,
                        children: [
                          Text('Frequency of stations by price', style: TextStyle(color: Colors.black, fontSize: widget.fontSize, fontWeight: FontWeight.bold)),
                          Text('  - num of stations: ${citiesToCountsOfStations[city]}', style: TextStyle(color: Colors.black, fontSize: widget.fontSize)),
                          Text('  - lowest price: €${keys.first/1000}', style: TextStyle(color: Colors.green, fontSize: widget.fontSize)),
                          Text('  - 1st quartile: €${quartileStart/1000}', style: TextStyle(color: Colors.black54, fontSize: widget.fontSize)),
                          Text('  - median price: €${median/1000}', style: TextStyle(color: Colors.purple, fontSize: widget.fontSize)),
                          Text('  - 3rd quartile: €${quartileEnd/1000}', style: TextStyle(color: Colors.black54, fontSize: widget.fontSize)),
                          Text('  - highest price: €${keys.last/1000}', style: TextStyle(color: Colors.red, fontSize: widget.fontSize)),
                          const SizedBox(height: 10),
                        ],
                      )
                    ],
                  )
              ),
            )
        )
    );
  }
}

// From https://stackoverflow.com/a/60528001
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}