import 'dart:async';
import 'dart:convert';

import 'package:cfg_flutter/keys.dart';
import 'package:cfg_flutter/model/brands.dart';
import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/model/location_model.dart';
import 'package:cfg_flutter/model/range.dart';
import 'package:cfg_flutter/util.dart';
import 'package:cfg_flutter/view_mode.dart';
import 'package:cfg_flutter/widgets/about.dart';
import 'package:cfg_flutter/widgets/info_tile.dart';
import 'package:cfg_flutter/widgets/settings_page.dart';
import 'package:cfg_flutter/widgets/short_drawer_header.dart';
import 'package:cfg_flutter/widgets/filter_brands_page.dart';
import 'package:cfg_flutter/widgets/privacy.dart';
// conditional import
// https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files
import 'package:cfg_flutter/widgets/station_page_none.dart' // default option
  if (dart.library.io) 'package:cfg_flutter/widgets/station_page_native.dart' // native
  if (dart.library.html) 'package:cfg_flutter/widgets/station_page_web.dart'; // web app
import 'package:cfg_flutter/widgets/stations_page.dart';
import 'package:cfg_flutter/widgets/syncing_progress_indicator.dart';
import 'package:cfg_flutter/widgets/analytics_page.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'dart:io';
import 'model/coordinates.dart';
import 'networking.dart';

void main() {
  // prepare admob
  WidgetsFlutterBinding.ensureInitialized();
  if(!kIsWeb) {
    MobileAds.instance.initialize();
  }

  runApp(CyprusFuelGuideApp());
}

class CyprusFuelGuideApp extends StatelessWidget {

  static final router = FluroRouter();

  CyprusFuelGuideApp({super.key}) {
    defineRoutes(router);
  }

  void defineRoutes(FluroRouter router) {
    router.define("/", handler: Handler(handlerFunc: (context, params) => const CyprusFuelGuideAppPage(title: 'Cyprus Fuel Guide')));
    router.define("/overview", handler: Handler(handlerFunc: (context, params) => const CyprusFuelGuideAppPage(title: 'Cyprus Fuel Guide')));
    router.define("/stationsByBestValue", handler: Handler(handlerFunc: (context, params) => const CyprusFuelGuideAppPage(title: 'Best value for your location', viewMode: ViewMode.bestValue)));
    router.define("/stationsByPrice", handler: Handler(handlerFunc: (context, params) => const CyprusFuelGuideAppPage(title: 'All stations by price', viewMode: ViewMode.cheapest)));
    router.define("/stationsByDistance", handler: Handler(handlerFunc: (context, params) => const CyprusFuelGuideAppPage(title: 'All stations by distance', viewMode: ViewMode.nearest)));
    router.define("/favoriteStations", handler: Handler(handlerFunc: (context, params) => const CyprusFuelGuideAppPage(title: 'Favorite stations', viewMode: ViewMode.favorites)));
    router.define("/analytics", handler: Handler(handlerFunc: (context, params) => const AnalyticsPage(title: 'Analytics')));
    router.define("/station/:code", handler: Handler(handlerFunc: (context, params) => StationPage(code: params['code']![0])));
    router.define("/filterBrands", handler: Handler(handlerFunc: (context, params) => const FilterBrandsPage(title: 'Filter brands')));
    router.define("/settings", handler: Handler(handlerFunc: (context, params) => const SettingsPage(title: 'Settings')));
    router.define("/privacy", handler: Handler(handlerFunc: (context, params) => const PrivacyPage(title: 'Privacy')));
    router.define("/about", handler: Handler(handlerFunc: (context, params) => const AboutPage(title: 'About')));
  }

  static const String keyLastSynced = 'keyLastSynced';
  static const String keyLastUpdateTimestamp = 'keyLastUpdateTimestamp';
  static const String keyNumOfStations = 'keyNumOfStations';
  static const String keyLastRawJson = 'keyLastRawJson';
  static const String keyFavoriteStationCodesRawJson = 'keyFavoriteStationCodesRawJson';
  static const String keyBrandNamesRawJson = 'keyBrandNamesRawJson';
  static const String keySelectedFuelType = 'keySelectedFuelType';
  static const String keySelectedViewMode = 'keySelectedViewMode';
  static const String keyShowInGreek = 'keyShowInGreek';
  static const String keyRangeForBestValue = 'keyRangeForBestValue';
  static const String keyShowStatisticsInStationView = 'keyShowStatisticsInStationView';
  static const String keyShowStatisticsInStationsView = 'keyShowStatisticsInStationsView';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => LocationModel(),
        child: MaterialApp(
          title: 'Cyprus Fuel Guide',
          theme: ThemeData(
            primarySwatch: Colors.amber,
          ),
          initialRoute: '/',
          onGenerateRoute: CyprusFuelGuideApp.router.generator,
        )
    );
  }
}

class CyprusFuelGuideAppPage extends StatefulWidget {
  const CyprusFuelGuideAppPage({super.key, required this.title, this.viewMode = ViewMode.bestValue});

  final String title;
  final ViewMode viewMode;

  @override
  State<CyprusFuelGuideAppPage> createState() => _CyprusFuelGuideAppPageState();
}

class _CyprusFuelGuideAppPageState extends State<CyprusFuelGuideAppPage> {

  bool _isSyncing = true;
  SyncResponse? _syncResponse;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

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

  int _lastSynced = 0;

  _synchronize() {
    setState(() => _isSyncing = true);

    _prefs.then((SharedPreferences sharedPreferences) {
      sync().then((String rawJson) {
        SyncResponse syncResponse = SyncResponse.fromRawJson(rawJson);

        _syncResponse = syncResponse;
        int lastSynced = DateTime.now().millisecondsSinceEpoch;
        _prefs.then((SharedPreferences sharedPreferences) {
          sharedPreferences.setInt(CyprusFuelGuideApp.keyLastSynced, lastSynced);
          sharedPreferences.setInt(CyprusFuelGuideApp.keyLastUpdateTimestamp, syncResponse.lastUpdated);
          sharedPreferences.setInt(CyprusFuelGuideApp.keyNumOfStations, syncResponse.stations.length);
          sharedPreferences.setString(CyprusFuelGuideApp.keyLastRawJson, rawJson);
        });

        setState(() {
          _isSyncing = false;
          _lastSynced = lastSynced;
        });
      });
    });
  }

  _loadFromPrefs() {
    // Loading raw JSON from prefs
    _prefs.then((SharedPreferences sharedPreferences) {
      final String? rawJson = sharedPreferences.getString(CyprusFuelGuideApp.keyLastRawJson);
      // print('cfg Loaded raw JSON: ${rawJson == null ? 'null' : rawJson.substring(0,10)}');
      _syncResponse = rawJson == null ? null : SyncResponse.fromRawJson(rawJson);
      setState(() => _isSyncing = false);
    });
  }

  late FuelType _fuelType = FuelType.petrol95;

  _selectFuelType(FuelType? fuelType) {
    _prefs.then((SharedPreferences sharedPreferences) {
      fuelType = fuelType ?? FuelType.petrol95;
      sharedPreferences.setInt(CyprusFuelGuideApp.keySelectedFuelType, fuelType!.index);
      setState(() => _fuelType = fuelType!);
    });
  }

  late ViewMode _viewMode = ViewMode.cheapest;

  _selectViewMode(ViewMode? viewMode) {
    _prefs.then((SharedPreferences sharedPreferences) {
      viewMode = viewMode ?? ViewMode.cheapest;
      sharedPreferences.setInt(CyprusFuelGuideApp.keySelectedViewMode, viewMode!.index);
      setState(() => _viewMode = viewMode!);
      switch(_viewMode) {
        case ViewMode.bestValue:
          CyprusFuelGuideApp.router.navigateTo(context, '/stationsByBestValue');
          break;
        case ViewMode.cheapest:
          CyprusFuelGuideApp.router.navigateTo(context, '/stationsByPrice');
          break;
        case ViewMode.nearest:
          CyprusFuelGuideApp.router.navigateTo(context, '/stationsByDistance');
          break;
        case ViewMode.favorites:
          CyprusFuelGuideApp.router.navigateTo(context, '/favoriteStations');
          break;
      }
    });
  }

  late Brands _brands = Brands.empty();

  _loadBrandsFromPrefs() {
    // load selected brands
    _prefs.then((SharedPreferences prefs) {
      String? brandNamesRawJson = prefs.getString(
          CyprusFuelGuideApp.keyBrandNamesRawJson);
      setState(() {
        _brands = brandNamesRawJson != null
            ? Brands.fromJson(jsonDecode(brandNamesRawJson))
            : Brands.empty();
      });
    });
  }

  late bool _showStatisticsInStationsView = true;

  _loadStatisticsFromPrefs() {
    _prefs.then((SharedPreferences prefs) {
      bool showStatisticsInStationsView = prefs.getBool(CyprusFuelGuideApp.keyShowStatisticsInStationsView) ?? true;
      setState(() {
        _showStatisticsInStationsView = showStatisticsInStationsView;
      });
    });
  }

  late Range _selectedRange = RangeExtension.defaultRange;

  _loadSelectedRangeFromPrefs() {
    _prefs.then((SharedPreferences prefs) {
      int selectedRange = prefs.getInt(
          CyprusFuelGuideApp.keyRangeForBestValue) ?? RangeExtension.defaultRange.value;
      setState(() {
        _selectedRange = RangeExtension.getFromValue(selectedRange);
      });
    });
  }

  _reloadAfterSettings() {
    _loadStatisticsFromPrefs();
    _loadSelectedRangeFromPrefs();
  }

  late String _version = '0.0.0'; // todo

  late StreamSubscription<Position> _positionStream;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      // load saved fuel type selection
      int fuelTypeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      _fuelType = FuelType.values[fuelTypeIndex];
      // load saved view mode selection
      int viewModeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedViewMode) ?? ViewMode.bestValue.index;
      _viewMode = ViewMode.values[viewModeIndex];
      // load last synced value
      int lastSynced = prefs.getInt(CyprusFuelGuideApp.keyLastSynced) ?? 0;
      _lastSynced = lastSynced;

      int millisecondsSinceLastSync = DateTime.now().millisecondsSinceEpoch - lastSynced;
      // Check if need to sync...
      if(lastSynced == 0 || millisecondsSinceLastSync > Util.oneHourInMilliseconds) {
        try {
          _synchronize();
        } on Error { // if sync fails (e.g. not connected) then load from prefs
          // Error syncing from internet
          _loadFromPrefs();
        }
      } else {
        // No need to sync - loading from prefs
        _loadFromPrefs();
      }

      setState(() {}); // trigger a state update

      // // load favorites
      // final String? favoriteStationCodesRawJson = prefs.getString(
      //     CyprusFuelGuideApp.keyFavoriteStationCodesRawJson);
      // _favorites = favoriteStationCodesRawJson != null ? Favorites.fromJson(
      //     jsonDecode(favoriteStationCodesRawJson)) : Favorites.empty();
    });

    // PackageInfo.fromPlatform().then((PackageInfo packageInfo) => setState(() {
    //   _version = 'Version ${packageInfo.version}-${packageInfo.buildNumber}';
    // }));

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      Coordinates currentCoordinates = Coordinates(position.latitude, position.longitude);
      Provider.of<LocationModel>(context, listen: false).update(currentCoordinates);
    });
  }

  @override
  void deactivate() {
    _positionStream.cancel();
    super.deactivate();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    if (!_loadingAnchoredBanner) {
      _loadingAnchoredBanner = true;
      if(!kIsWeb) { // no ads on Web
        _createAnchoredBanner(context);
      }
    }

    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.amber,
        ),
        home: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(widget.title),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero, // remove any padding from the ListView.
              children: [

                const ShortDrawerHeader(),

                ListTile(
                  leading: const Icon(Icons.book_outlined, color: Colors.brown),
                  subtitle: Text('Selected starting page', style: Theme.of(context).textTheme.bodySmall),
                  dense: true,
                  title: DropdownButton<ViewMode>(
                    // isDense: true,
                    items: [
                      DropdownMenuItem(
                          value: ViewMode.bestValue,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: _viewMode == ViewMode.bestValue ? FontWeight.bold : FontWeight.normal),
                              children: <TextSpan>[
                                const TextSpan(text: 'Best value'),
                                TextSpan(text: '\nStations within ${_selectedRange.name}, by price', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                              ],
                            ),
                          )
                      ),
                      DropdownMenuItem(
                          value: ViewMode.cheapest,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: _viewMode == ViewMode.cheapest ? FontWeight.bold : FontWeight.normal),
                              children: const <TextSpan>[
                                TextSpan(text: 'Cheapest'),
                                TextSpan(text: '\nAll stations, sorted by price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                              ],
                            ),
                          )
                      ),
                      DropdownMenuItem(
                          value: ViewMode.nearest,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: _viewMode == ViewMode.nearest ? FontWeight.bold : FontWeight.normal),
                              children: const <TextSpan>[
                                TextSpan(text: 'Nearest'),
                                TextSpan(text: '\nAll stations, sorted by distance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                              ],
                            ),
                          )
                      ),
                      DropdownMenuItem(
                          value: ViewMode.favorites,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: _viewMode == ViewMode.favorites ? FontWeight.bold : FontWeight.normal),
                              children: const <TextSpan>[
                                TextSpan(text: 'Favorites'),
                                TextSpan(text: '\nFavorite stations, sorted by price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                              ],
                            ),
                          )
                      ),
                    ],
                    value: _viewMode,
                    isExpanded: true,
                    underline: const SizedBox(), // hide underline
                    onChanged: (ViewMode? viewMode) => _selectViewMode(viewMode),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.local_gas_station_outlined, color: Colors.brown),
                  subtitle: Text('Selected fuel type', style: Theme.of(context).textTheme.bodySmall),
                  dense: true,
                  title: DropdownButton<FuelType>(
                    items: [
                      DropdownMenuItem(
                          value: FuelType.petrol95,
                          child: Text('Unleaded 95', style: _fuelType == FuelType.petrol95 ? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 13, fontWeight: FontWeight.normal))
                      ),
                      DropdownMenuItem(
                          value: FuelType.petrol98,
                          child: Text('Unleaded 98', style: _fuelType == FuelType.petrol98 ? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 13, fontWeight: FontWeight.normal))
                      ),
                      DropdownMenuItem(
                          value: FuelType.diesel,
                          child: Text('Diesel', style: _fuelType == FuelType.diesel ? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 13, fontWeight: FontWeight.normal))
                      ),
                      DropdownMenuItem(
                          value: FuelType.heating,
                          child: Text('Heating', style: _fuelType == FuelType.heating ? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 13, fontWeight: FontWeight.normal))
                      ),
                      DropdownMenuItem(
                          value: FuelType.kerosene,
                          child: Text('Kerosene', style: _fuelType == FuelType.kerosene ? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 13, fontWeight: FontWeight.normal))
                      ),
                    ],
                    value: _fuelType,
                    isExpanded: true,
                    underline: const SizedBox(), // hide underline
                    onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                  ),
                ),

                // const Divider(color: Colors.brown),
                ListTile(
                  title: const Text('Filter brands'),
                  subtitle: Text(_brands.numOfUnchecked() == 0 ? 'Viewing all brands' : 'Viewing ${_brands.numOfChecked()} brands (${_brands.numOfUnchecked()} hidden)'),
                  dense: true,
                  leading: const Icon(Icons.filter_list_outlined, color: Colors.brown),
                  onTap: () {
                    _scaffoldKey.currentState!.closeDrawer();
                    CyprusFuelGuideApp.router.navigateTo(context, '/filterBrands').then((value) => _loadBrandsFromPrefs());
                  },
                ),

                const Divider(color: Colors.brown),
                ListTile(
                  title: const Text('Analytics'),
                  subtitle: Text('Statistics about fuel prices', style: Theme.of(context).textTheme.bodySmall),
                  leading: const Icon(Icons.stacked_line_chart_outlined),
                  onTap: () {
                    CyprusFuelGuideApp.router.navigateTo(context, '/analytics');
                  },
                ),
                // ListTile(
                //   title: const Text('Trends'),
                //   subtitle: Text('How fuel prices change', style: Theme.of(context).textTheme.bodySmall),
                //   leading: const Icon(Icons.auto_graph_outlined),
                //   onTap: () {
                //     CyprusFuelGuideApp.router.navigateTo(context, '/trends');
                //   },
                // ),

                const Divider(color: Colors.brown),
                ListTile(
                  dense: true,
                  leading: const SizedBox(),
                  subtitle: Text('Data from the Ministry of Energy, Commerce and Industry - meci.gov.cy', style: Theme.of(context).textTheme.bodySmall,),
                ),
                ListTile(
                  title: const Text('Synchronize'),
                  subtitle: Text(_isSyncing ? 'Syncing ...' : Util.getSynchronizeSubtitle(_lastSynced)),
                  dense: true,
                  leading: const Icon(Icons.sync, color: Colors.brown),
                  onTap: () {
                    _isSyncing || (DateTime.now().millisecondsSinceEpoch - _lastSynced < Util.oneMinuteInMilliseconds) ? null : _synchronize();
                  },
                ),
                ListTile(
                  title: const Text('Settings'),
                  dense: true,
                  leading: const Icon(Icons.settings_outlined, color: Colors.brown),
                  onTap: () {
                    _scaffoldKey.currentState!.closeDrawer();
                    CyprusFuelGuideApp.router.navigateTo(context, '/settings').then((value) => setState(() => _reloadAfterSettings()));
                  },
                ),

                const Divider(color: Colors.brown),
                ListTile(
                  title: const Text('Privacy & Terms of Use'),
                  dense: true,
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.brown),
                  onTap: () {
                    _scaffoldKey.currentState!.closeDrawer();
                    CyprusFuelGuideApp.router.navigateTo(context, '/privacy');
                  },
                ),
                ListTile(
                  title: const Text('About'),
                  subtitle: Text(_version),
                  dense: true,
                  leading: const Icon(Icons.info_outline, color: Colors.brown),
                  onTap: () {
                    _scaffoldKey.currentState!.closeDrawer();
                    CyprusFuelGuideApp.router.navigateTo(context, '/about');
                  },
                ),
              ],
            ),
          ),
          body: _isSyncing
              ? const SyncingProgressIndicator()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InfoTileWidget(label: ' ⛽ ${Util.nameOfViewMode(_viewMode)} ${_viewMode==ViewMode.bestValue ? '(within ${_selectedRange.name})' : ''} · ${Util.name(_fuelType)}'),
              Container(color: Colors.brown, height: 1),
              Expanded(
                  child: _getSelectedView()
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
          ),
        )
    );
  }

  Widget _getSelectedView() {
    switch(widget.viewMode) {
      case ViewMode.bestValue:
        return StationsPage(title: 'Best Value', fuelType: _fuelType, viewMode: ViewMode.bestValue, syncResponse: _syncResponse!, brands: _brands, showStatisticsInStationsView: _showStatisticsInStationsView, selectedRange: _selectedRange);
      case ViewMode.cheapest:
        return StationsPage(title: 'Cheapest', fuelType: _fuelType, viewMode: ViewMode.cheapest, syncResponse: _syncResponse!, brands: _brands, showStatisticsInStationsView: _showStatisticsInStationsView, selectedRange: _selectedRange);
      case ViewMode.nearest:
        return StationsPage(title: 'Nearest', fuelType: _fuelType, viewMode: ViewMode.nearest, syncResponse: _syncResponse!, brands: _brands, showStatisticsInStationsView: _showStatisticsInStationsView, selectedRange: _selectedRange);
      case ViewMode.favorites:
        return StationsPage(title: 'Favorites', fuelType: _fuelType, viewMode: ViewMode.favorites, syncResponse: _syncResponse!, brands: _brands, showStatisticsInStationsView: _showStatisticsInStationsView, selectedRange: _selectedRange);
    }
  }
}