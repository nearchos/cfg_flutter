import 'dart:async';
import 'dart:io' as io;

import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:cfg_flutter/widgets/distance_view.dart';
import 'package:cfg_flutter/widgets/price_view.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:greek_tools/greek_tools.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g_f_maps;

import '../keys.dart';
import '../main.dart';
import '../model/location_model.dart';
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

  final int zoomLevel = 16;

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

  final Completer<g_f_maps.GoogleMapController> _controller = Completer();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Station? _station;
  Price? _price;
  FuelType _fuelType = FuelType.petrol95;
  String _title = 'Station';
  bool _showInGreek = false;

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
    }
    _createAnchoredBanner(context);
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
                  child: FutureBuilder<g_f_maps.Marker>(
                      future: _getMarker(_station!),
                      builder: (BuildContext context, AsyncSnapshot<g_f_maps.Marker> snapshot) {
                        if (snapshot.hasData) {
                          return g_f_maps.GoogleMap(
                            mapType: g_f_maps.MapType.normal,
                            initialCameraPosition: g_f_maps.CameraPosition(
                              target: g_f_maps.LatLng(_station!.lat, _station!.lng),
                              zoom: zoomLevel.toDouble(),
                            ),
                            onMapCreated: (g_f_maps.GoogleMapController controller) {
                              _controller.complete(controller);
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
                        child: Consumer<LocationModel>(
                            builder: (context, locationModel, child) {
                              LocationData? locationData = locationModel.locationData;
                              double distanceInMeters = locationData == null
                                  ?
                              double.infinity
                                  :
                              Util.calculateDistanceInMeters(locationData.latitude, locationData.longitude, _station!.lat, _station!.lng);
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

  Future<g_f_maps.Marker> _getMarker(final Station station) async {
    // init bitmap for marker icon
    final g_f_maps.BitmapDescriptor markerIcon = await g_f_maps.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)), 'images/brown_marker.png');

    // creating a new marker
    return g_f_maps.Marker(
        markerId: g_f_maps.MarkerId(station.code),
        position: g_f_maps.LatLng(station.lat, station.lng),
        infoWindow: g_f_maps.InfoWindow(title: toGreeklish(station.name), snippet: toGreeklish(station.address)),
        icon: markerIcon
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
    _launchMapsUrl('${_station!.name}, ${_station!.address}', _station!.lat, _station!.lng);
  }

  _launchMapsUrl(String title, double lat, double lon) async {
    final availableMaps = await MapLauncher.installedMaps;

    await availableMaps.first.showMarker(
        coords: Coords(lat, lon),
        title: title
    );
  }
}