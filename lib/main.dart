import 'package:cfg_flutter/keys.dart';
import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/util.dart';
import 'package:cfg_flutter/widgets/about.dart';
import 'package:cfg_flutter/widgets/cfg_drawer_header.dart';
import 'package:cfg_flutter/widgets/fuel_page.dart';
import 'package:cfg_flutter/widgets/syncing_progress_indicator.dart';
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
  MobileAds.instance.initialize();

  runApp(const CyprusFuelGuideApp());
}

class CyprusFuelGuideApp extends StatelessWidget {
  const CyprusFuelGuideApp({Key? key}) : super(key: key);

  static const String keyLastSynced = 'KEY_LAST_SYNCED';
  static const String keyLastUpdateTimestamp = 'KEY_LAST_UPDATE_TIMESTAMP';
  static const String keyLastRawJson = 'KEY_LAST_RAW_JSON';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Cyprus Fuel Guide',
        theme: ThemeData(
          primarySwatch: Colors.amber,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const CyprusFuelGuideAppPage(title: 'Cyprus Fuel Guide'),
          '/about': (context) => const AboutPage(title: 'About', syncResponse: null),
        }
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

  @override
  void initState() {
    super.initState();

    _prefs.then((SharedPreferences prefs) {
      int lastSynced = prefs.getInt(CyprusFuelGuideApp.keyLastSynced) ?? 0;
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
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    if (!_loadingAnchoredBanner) {
      _loadingAnchoredBanner = true;
      _createAnchoredBanner(context);
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
                ListTile(
                  title: const Text('Favorites'),
                  subtitle: Text(_getFavoritesSubtitle()),
                  leading: const Icon(Icons.favorite_border_outlined),
                  onTap: () {
                    // todo
                    _scaffoldKey.currentState!.closeDrawer();
                  },
                ),
                ListTile(
                  title: const Text('Statistics'),
                  subtitle: Text(_getStatisticsSubtitle()),
                  leading: const Icon(Icons.stacked_line_chart),
                  onTap: () {
                    // todo
                    _scaffoldKey.currentState!.closeDrawer();
                  },
                ),
                ListTile(
                  title: const Text('Synchronize'),
                  subtitle: Text(_isSyncing ? 'Syncing ...' : _getSynchronizeSubtitle()),
                  leading: const Icon(Icons.sync),
                  onTap: () {
                    _isSyncing || (DateTime.now().millisecondsSinceEpoch - _lastSynced < Util.oneMinuteInMilliseconds) ? null : _synchronize();
                  },
                ),
                ListTile(
                  title: const Text('About'),
                  subtitle: const Text('Developed by aspectsense.com'),
                  leading: const Icon(Icons.info_outline),
                  onTap: () {
                    _scaffoldKey.currentState!.closeDrawer();
                    Navigator.pushNamed(context, '/about', arguments: {_syncResponse: _syncResponse});
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

  String _getFavoritesSubtitle() {
    return 'You have no favorites'; // todo
  }

  String _getStatisticsSubtitle() {
    if(_syncResponse == null) {
      return 'Price trends across stations';
    } else {
      return 'Price trends across ${_syncResponse!.stations.length} stations';
    }
  }

  String _getSynchronizeSubtitle() {
    if(_lastSynced == 0) {
      return 'Not synced yet';
    } else {
      int millisecondsSinceLastSync = DateTime.now().millisecondsSinceEpoch - _lastSynced;
      if(millisecondsSinceLastSync < 2 * Util.oneSecondInMilliseconds) {
        return 'Last synced just now!';
      } else if(millisecondsSinceLastSync < Util.oneMinuteInMilliseconds) {
        return 'Last synced ${millisecondsSinceLastSync ~/ Util.oneSecondInMilliseconds} seconds ago';
      } else if(millisecondsSinceLastSync < 2 * Util.oneHourInMilliseconds) {
        return 'Last synced ${millisecondsSinceLastSync ~/ Util.oneMinuteInMilliseconds} minutes ago';
      } else {
        return 'Last synced ${millisecondsSinceLastSync ~/ Util.oneHourInMilliseconds} hours ago';
      }
    }
  }
}
