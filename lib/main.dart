import 'dart:async';
import 'dart:convert';

import 'package:cfg_flutter/keys.dart';
import 'package:cfg_flutter/model/brands.dart';
import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/model/location_model.dart';
import 'package:cfg_flutter/util.dart';
import 'package:cfg_flutter/view_mode.dart';
import 'package:cfg_flutter/widgets/about.dart';
import 'package:cfg_flutter/widgets/info_tile.dart';
import 'package:cfg_flutter/widgets/short_drawer_header.dart';
import 'package:cfg_flutter/widgets/dot_radio_list_tile.dart';
import 'package:cfg_flutter/widgets/filter_brands_page.dart';
import 'package:cfg_flutter/widgets/overview_page.dart';
import 'package:cfg_flutter/widgets/privacy.dart';
// conditional import
// https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files
import 'package:cfg_flutter/widgets/station_page_none.dart' // default option
  if (dart.library.io) 'package:cfg_flutter/widgets/station_page_native.dart' // native
  if (dart.library.html) 'package:cfg_flutter/widgets/station_page_web.dart'; // web app
import 'package:cfg_flutter/widgets/stations_page.dart';
import 'package:cfg_flutter/widgets/syncing_progress_indicator.dart';
import 'package:cfg_flutter/widgets/trends_page.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'dart:io';
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

  CyprusFuelGuideApp({Key? key}) : super(key: key) {
    defineRoutes(router);
  }

  void defineRoutes(FluroRouter router) {
    router.define("/", handler: Handler(handlerFunc: (context, params) => const CyprusFuelGuideAppPage(title: 'Cyprus Fuel Guide')));
    router.define("/stationsByPrice", handler: Handler(handlerFunc: (context, params) => const StationsPage(title: 'Stations by price', viewMode: ViewMode.cheapest)));
    router.define("/stationsByDistance", handler: Handler(handlerFunc: (context, params) => const StationsPage(title: 'Stations by distance', viewMode: ViewMode.nearest)));
    router.define("/favoriteStations", handler: Handler(handlerFunc: (context, params) => const StationsPage(title: 'Favorite stations', viewMode: ViewMode.favorites)));
    router.define("/trends", handler: Handler(handlerFunc: (context, params) => const TrendsPage(title: 'Trends')));
    router.define("/station/:code", handler: Handler(handlerFunc: (context, params) => StationPage(code: params['code']![0])));
    router.define("/filterBrands", handler: Handler(handlerFunc: (context, params) => const FilterBrandsPage(title: 'Filter brands')));
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
  static const String keyShowInGreek = 'keyShowInGreek';

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
  const CyprusFuelGuideAppPage({Key? key, required this.title}) : super(key: key);

  final String title;

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

  String _version = '...';

  StreamSubscription<LocationData>? _locationStreamSubscription;

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      // load saved fuel type selection
      int fuelTypeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      _fuelType = FuelType.values[fuelTypeIndex];
      // load saved view mode selection
      // int viewModeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedViewMode) ?? ViewMode.overview.index;
      // _viewMode = ViewMode.values[viewModeIndex];
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
    });

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) => setState(() {
      _version = 'Version ${packageInfo.version}-${packageInfo.buildNumber}';
    }));

    Util.requestLocation().then((Location location) {
      _locationStreamSubscription = location.onLocationChanged.listen((LocationData currentLocationData) {
        Provider.of<LocationModel>(context, listen: false).update(currentLocationData);
      });
    });
  }

  @override
  void deactivate() {
    _locationStreamSubscription?.cancel();
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

                DotRadioListTile<FuelType>(
                  value: FuelType.petrol95,
                  groupValue: _fuelType,
                  title: 'Unleaded 95',
                  iconData: Icons.local_gas_station_outlined,
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                DotRadioListTile<FuelType>(
                  value: FuelType.petrol98,
                  groupValue: _fuelType,
                  title: 'Unleaded 98',
                  iconData: Icons.local_gas_station_outlined,
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                DotRadioListTile<FuelType>(
                  value: FuelType.diesel,
                  groupValue: _fuelType,
                  title: 'Diesel',
                  iconData: Icons.local_gas_station_outlined,
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                DotRadioListTile<FuelType>(
                  value: FuelType.heating,
                  groupValue: _fuelType,
                  title: 'Heating',
                  iconData: Icons.local_gas_station_outlined,
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                DotRadioListTile<FuelType>(
                  value: FuelType.kerosene,
                  groupValue: _fuelType,
                  title: 'Kerosene',
                  iconData: Icons.local_gas_station_outlined,
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),

                const Divider(color: Colors.brown),
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
                  leading: const SizedBox(),
                  subtitle: Text('Data from the Ministry of Energy, Commerce, Industry, and Tourism', style: Theme.of(context).textTheme.bodySmall,),
                ),
                ListTile(
                  title: const Text('Synchronize'),
                  subtitle: Text(_isSyncing ? 'Syncing ...' : _getSynchronizeSubtitle()),
                  dense: true,
                  leading: const Icon(Icons.sync, color: Colors.brown),
                  onTap: () {
                    _isSyncing || (DateTime.now().millisecondsSinceEpoch - _lastSynced < Util.oneMinuteInMilliseconds) ? null : _synchronize();
                  },
                ),

                const Divider(color: Colors.brown),
                ListTile(
                  title: const Text('Privacy'),
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
              InfoTileWidget(label: ' ⛽ Overview · ${Util.name(_fuelType)}'),
              Expanded(
                  child: Overview(syncResponse: _syncResponse)
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

  String _getSynchronizeSubtitle() {
    if(_lastSynced == 0) {
      return 'Not synced yet';
    } else {
      int millisecondsSinceLastSync = DateTime.now().millisecondsSinceEpoch - _lastSynced;
      if(millisecondsSinceLastSync < 2 * Util.oneSecondInMilliseconds) {
        return 'Last synced just now!';
      } else if(millisecondsSinceLastSync < 2 * Util.oneMinuteInMilliseconds) {
        return 'Last synced ${millisecondsSinceLastSync ~/ Util.oneSecondInMilliseconds} seconds ago';
      } else if(millisecondsSinceLastSync < 2 * Util.oneHourInMilliseconds) {
        return 'Last synced ${millisecondsSinceLastSync ~/ Util.oneMinuteInMilliseconds} minutes ago';
      } else {
        return 'Last synced ${millisecondsSinceLastSync ~/ Util.oneHourInMilliseconds} hours ago';
      }
    }
  }
}