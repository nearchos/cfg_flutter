import 'dart:async';
import 'dart:io';

import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:cfg_flutter/widgets/distance_view.dart';
import 'package:cfg_flutter/widgets/price_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:greek_tools/greek_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as g_maps;

import '../keys.dart';
import '../main.dart';
import '../model/price.dart';
import '../model/station.dart';
import '../util.dart';

class StationPage extends StatefulWidget {
  const StationPage({Key? key, required this.code}) : super(key: key);

  final String code; // station code

  @override
  State<StationPage> createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> {

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
      adUnitId: Platform.isAndroid ? adUnitIdAndroid : adUnitIdIOS,
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

  final Completer<g_maps.GoogleMapController> _controller = Completer();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Station? _station;
  Price? _price;
  FuelType _fuelType = FuelType.petrol95;
  String _title = 'Station';
  bool _showInGreek = false;

  LocationData? _locationData;//todo

  @override
  void setState(VoidCallback fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      final String? lastRawJson = prefs.getString(CyprusFuelGuideApp.keyLastRawJson);
      final SyncResponse syncResponse = SyncResponse.fromRawJson(lastRawJson!);
      List<Station> stations = syncResponse.stations;
      List<Price> prices = syncResponse.prices;
      int fuelTypeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      bool showInGreek = prefs.getBool(CyprusFuelGuideApp.keyShowInGreek) ?? false;

      setState(() {
        _station = stations.firstWhere((s) => s.code == widget.code);
        _price = prices.firstWhere((p) => p.stationCode == widget.code);
        _title = _station!.name;
        _fuelType = FuelType.values[fuelTypeIndex];
        _showInGreek = showInGreek;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadingAnchoredBanner) {
      _loadingAnchoredBanner = true;
      if(!kIsWeb) { // no ads on Web
        _createAnchoredBanner(context);
      }
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(_title),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: Column(
          children: [
            Expanded(
              child: _station == null || _price == null
                  ?
              const LinearProgressIndicator()
                  :
              _getStationView(),
            ),

            kIsWeb || _anchoredBanner == null
                ? Container() // empty if no ads
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

  Widget _getStationView() {
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
                  const VerticalDivider(width: 1, color: Colors.brown),
                  _getFuelBox(FuelType.petrol98, _price!.prices[FuelType.petrol98.index], _fuelType==FuelType.petrol98),
                  const VerticalDivider(width: 1, color: Colors.brown),
                  _getFuelBox(FuelType.diesel, _price!.prices[FuelType.diesel.index], _fuelType==FuelType.diesel),
                  const VerticalDivider(width: 1, color: Colors.brown),
                  _getFuelBox(FuelType.heating, _price!.prices[FuelType.heating.index], _fuelType==FuelType.heating),
                  const VerticalDivider(width: 1, color: Colors.brown),
                  _getFuelBox(FuelType.kerosene, _price!.prices[FuelType.kerosene.index], _fuelType==FuelType.kerosene),
                ],
              ),
              Container(height: 1, color: Colors.brown),
              Expanded(
                  child: FutureBuilder<g_maps.Marker>(
                      future: _getMarker(_station!),
                      builder: (BuildContext context,
                          AsyncSnapshot<g_maps.Marker> snapshot) {
                        if (snapshot.hasData) {
                          return g_maps.GoogleMap(
                            mapType: g_maps.MapType
                                .normal,
                            initialCameraPosition: g_maps
                                .CameraPosition(
                              target: g_maps.LatLng(_station!.lat, _station!.lng),
                              zoom: 16, //todo
                            ),
                            onMapCreated: (g_maps
                                .GoogleMapController controller) {
                              _controller.complete(
                                  controller);
                            },
                            markers: {snapshot.data!},
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }
                  )
              ),
              Container(height: 1, color: Colors.brown),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(width: 48, child: DistanceView(distanceInMeters: _getDistance(), fontSize: 20)),
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
                        child: SizedBox(width: 48, child: Util.imageForBrand(_station!.brand)),
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

  Future<g_maps.Marker> _getMarker(final Station station) async {
    // init bitmap for marker icon
    final g_maps.BitmapDescriptor markerIcon = await g_maps.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)), 'icons/amber_marker.png');

    // creating a new marker
    return g_maps.Marker(
        markerId: g_maps.MarkerId(station.code),
        position: g_maps.LatLng(station.lat, station.lng),
        infoWindow: g_maps.InfoWindow(title: station.name, snippet: station.address), // todo Greeklish
        icon: markerIcon
    );
  }

  double _getDistance() {
    return _locationData == null
        ?
    double.infinity
        :
    Util.calculateDistanceInMeters(_locationData!.latitude, _locationData!.longitude, _station!.lat, _station!.lng);
  }

  void _navigate() {
    //todo
  }

  void _call() {
    //todo
  }
}