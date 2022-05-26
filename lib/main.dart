import 'package:cfg_flutter/keys.dart';
import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/util.dart';
import 'package:cfg_flutter/view_mode.dart';
import 'package:cfg_flutter/widgets/about.dart';
import 'package:cfg_flutter/widgets/cfg_drawer_header.dart';
import 'package:cfg_flutter/widgets/cfg_radio_list-tile.dart';
import 'package:cfg_flutter/widgets/fuel_page.dart';
import 'package:cfg_flutter/widgets/station_page.dart';
import 'package:cfg_flutter/widgets/syncing_progress_indicator.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cfg_flutter/model/sync_response.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
    router.define("/station/:code", handler: Handler(handlerFunc: (context, params) => StationPage(title: 'Station', code: params['code']![0])));
    // todo add '/privacy'
    router.define("/about", handler: Handler(handlerFunc: (context, params) => const AboutPage(title: 'About')));
  }

  static const String keyLastSynced = 'KEY_LAST_SYNCED';
  static const String keyLastUpdateTimestamp = 'KEY_LAST_UPDATE_TIMESTAMP';
  static const String keyNumOfStations = 'KEY_NUM_OF_STATIONS';
  static const String keyLastRawJson = 'KEY_LAST_RAW_JSON';
  static const String keySelectedFuelType = 'KEY_SELECTED_FUEL_TYPE';
  static const String keySelectedViewMode = 'KEY_SELECTED_VIEW_MODE';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyprus Fuel Guide',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      initialRoute: '/',
      onGenerateRoute: CyprusFuelGuideApp.router.generator,
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
        _prefs.then((SharedPreferences sharedPreferences) => sharedPreferences.setInt(CyprusFuelGuideApp.keyLastSynced, lastSynced));
        _prefs.then((SharedPreferences sharedPreferences) => sharedPreferences.setInt(CyprusFuelGuideApp.keyLastUpdateTimestamp, syncResponse.lastUpdated));
        _prefs.then((SharedPreferences sharedPreferences) => sharedPreferences.setInt(CyprusFuelGuideApp.keyNumOfStations, syncResponse.stations.length));
        _prefs.then((SharedPreferences sharedPreferences) => sharedPreferences.setString(CyprusFuelGuideApp.keyLastRawJson, rawJson));

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

  late ViewMode _viewMode = ViewMode.overview;

  _selectViewMode(ViewMode? viewMode) {
    _prefs.then((SharedPreferences sharedPreferences) {
      viewMode = viewMode ?? ViewMode.cheapest;
      sharedPreferences.setInt(CyprusFuelGuideApp.keySelectedViewMode, viewMode!.index);
      setState(() => _viewMode = viewMode!);
    });
  }

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      // load saved fuel type selection
      int fuelTypeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedFuelType) ?? FuelType.petrol95.index;
      _fuelType = FuelType.values[fuelTypeIndex];
      // load saved view mode selection
      int viewModeIndex = prefs.getInt(CyprusFuelGuideApp.keySelectedViewMode) ?? ViewMode.overview.index;
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
    });
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
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'p95'),
                Tab(text: 'p98'),
                Tab(text: 'die',),
                Tab(text: 'hea',),
                Tab(text: 'ker',),
              ],
            ),
            title: Text(widget.title),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero, // remove any padding from the ListView.
              children: [

                const CfgDrawerHeader(),

                CfgRadioListTile<FuelType>(
                  value: FuelType.petrol95,
                  groupValue: _fuelType,
                  leading: 'P95',
                  dense: true,
                  title: 'Unleaded 95',
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                CfgRadioListTile<FuelType>(
                  value: FuelType.petrol98,
                  groupValue: _fuelType,
                  leading: 'P98',
                  dense: true,
                  title: 'Unleaded 98',
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                CfgRadioListTile<FuelType>(
                  value: FuelType.diesel,
                  groupValue: _fuelType,
                  leading: 'DIE',
                  dense: true,
                  title: 'Diesel',
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                CfgRadioListTile<FuelType>(
                  value: FuelType.heating,
                  groupValue: _fuelType,
                  leading: 'HEA',
                  dense: true,
                  title: 'Heating',
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),
                CfgRadioListTile<FuelType>(
                  value: FuelType.kerosene,
                  groupValue: _fuelType,
                  leading: 'KER',
                  dense: true,
                  title: 'Kerosene',
                  onChanged: (FuelType? fuelType) => _selectFuelType(fuelType),
                ),

                const Divider(),

                CfgRadioListTile<ViewMode>(
                  value: ViewMode.overview,
                  groupValue: _viewMode,
                  icon: const Icon(Icons.local_gas_station_outlined, color: Colors.brown,),
                  dense: true,
                  title: 'Overview',
                  onChanged: (ViewMode? viewMode) => _selectViewMode(viewMode),
                ),
                CfgRadioListTile<ViewMode>(
                  value: ViewMode.cheapest,
                  groupValue: _viewMode,
                  icon: const Icon(Icons.euro, color: Colors.brown,),
                  dense: true,
                  title: 'Cheapest',
                  onChanged: (ViewMode? viewMode) => _selectViewMode(viewMode),
                ),
                CfgRadioListTile<ViewMode>(
                  value: ViewMode.nearest,
                  groupValue: _viewMode,
                  icon: const Icon(Icons.near_me_outlined, color: Colors.brown,),
                  dense: true,
                  title: 'Nearest',
                  onChanged: (ViewMode? viewMode) => _selectViewMode(viewMode),
                ),
                CfgRadioListTile<ViewMode>(
                  value: ViewMode.favorites,
                  groupValue: _viewMode,
                  icon: const Icon(Icons.favorite_border_outlined, color: Colors.brown,),
                  dense: true,
                  title: 'Favorites',
                  onChanged: (ViewMode? viewMode) => _selectViewMode(viewMode),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Statistics'),
                  dense: true,
                  leading: const Icon(Icons.stacked_line_chart, color: Colors.brown),
                  onTap: () {
                    // todo
                    _scaffoldKey.currentState!.closeDrawer();
                    CyprusFuelGuideApp.router.navigateTo(context, '/station/${_syncResponse!.stations[2].code}');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Synchronize'),
                  subtitle: Text(_isSyncing ? 'Syncing ...' : _getSynchronizeSubtitle()),
                  dense: true,
                  leading: const Icon(Icons.sync, color: Colors.brown),
                  onTap: () {
                    _isSyncing || (DateTime.now().millisecondsSinceEpoch - _lastSynced < Util.oneMinuteInMilliseconds) ? null : _synchronize();
                  },
                ),
                ListTile(
                  title: const Text('About'),
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
              Expanded(
                  child: TabBarView(
                    children: [
                      FuelPage(fuelType: FuelType.petrol95, syncResponse: _syncResponse),
                      FuelPage(fuelType: FuelType.petrol98, syncResponse: _syncResponse),
                      FuelPage(fuelType: FuelType.diesel, syncResponse: _syncResponse),
                      FuelPage(fuelType: FuelType.heating, syncResponse: _syncResponse),
                      FuelPage(fuelType: FuelType.kerosene, syncResponse: _syncResponse),
                    ],
                  )),
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
        ),
      ),
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
