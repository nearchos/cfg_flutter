import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../util.dart';

class AboutPage extends StatefulWidget {

  final String title;

  const AboutPage({Key? key, required this.title}) : super(key: key);

  @override
  AboutState createState() => AboutState();
}

class AboutState extends State<AboutPage> {

  String? _version;
  late String databaseTitle = '';
  late String databaseSubtitle = '';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) => setState(() { _version = '${packageInfo.version}-${packageInfo.buildNumber}'; }));
    _prefs.then((SharedPreferences prefs) {
      final int lastUpdateTimestamp = prefs.getInt(CyprusFuelGuideApp.keyLastUpdateTimestamp) ?? 0;
      final int lastSynced = prefs.getInt(CyprusFuelGuideApp.keyLastSynced) ?? 0;
      final int numOfStations = prefs.getInt(CyprusFuelGuideApp.keyNumOfStations) ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      databaseTitle = 'Database with $numOfStations stations';
      databaseSubtitle = 'Prices last modified ${Util.timeInWords(now - lastUpdateTimestamp)} ago (server last contacted ${Util.timeInWords(now - lastSynced)} ago)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: ListView(
          children: [
            _getCard(Image.asset('icons/launcher.png', width: 32, height: 32), 'Cyprus Fuel Guide', 'http://cyprusfuelguide.com', _launchURI, 'http://cyprusfuelguide.com'),
            _getCard(const Icon(Icons.data_array, color: Colors.brown, size: 32), databaseTitle, databaseSubtitle, _launchURI, 'https://cyprusfuelguide.com'),
            _getCard(const Icon(Icons.code, color: Colors.brown, size: 32), 'Developed with ❤ by', 'http://aspectsense.com', _launchURI, 'http://aspectsense.com'),
            _getCard(const Icon(Icons.build, color: Colors.brown, size: 32), 'Open Source Software', 'Version $_version', _launchURI, 'https://cyprusfuelguide.com'),
            _getCard(const Icon(Icons.favorite, color: Colors.brown, size: 32), 'Loved the app?', 'Click to rate', _launchURI, _getMarketplaceLink()),
            Visibility(
              visible: !kIsWeb,
              child: _getCard(const Icon(Icons.share, color: Colors.brown, size: 32), 'Tell the world!', 'Share with your friends', _share, 'Get Cyprus Fuel Guide for Android and iOS for free at http://cyprusfuelguide.com'),
            )
          ],
        )
      // )
    );
  }

  Widget _getCard(Widget icon, String title, String subtitle, Function callback, String? callbackParameter) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: Card(
            elevation: 4,
            child: InkWell(
              onTap: () => callback(callbackParameter),
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
                            Text(title, style: Theme.of(context).textTheme.headline6),
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

  void _launchURI(String url) async =>
      await canLaunchUrl(Uri.parse(url)) ? await launchUrl(Uri.parse(url)) : throw 'Could not launch $url';

  void _share(String message) => Share.share(message);

  String? _getMarketplaceLink() {
    try {
      if(kIsWeb) {  // Web
        return 'http://cyprusfuelguide.com';
      }
      else if (Platform.isAndroid) { // Android
        return 'https://play.google.com/store/apps/details?id=com.aspectsense.fuelguidecy';
      } else if (Platform.isIOS) { // iOS
        // iOS-specific code
        return null; // todo replace with Apple's app store marketplace URL for this app
      }
    } catch(e) {
      debugPrint('Error: $e');
    }
    return null;
  }
}