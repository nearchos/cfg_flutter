import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {

  final String title;

  const PrivacyPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text('By using this app you agree to the following:', style: Theme.of(context).textTheme.subtitle2,),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                  child: Card(
                      elevation: 4,
                      child: InkWell(
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(width: 5),
                                const Icon(Icons.privacy_tip_outlined),
                                Container(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Privacy policy', style: Theme.of(context).textTheme.headline6),
                                      Container(height: 12),
                                      Text(privacyText, style: Theme.of(context).textTheme.caption),
                                    ],
                                  ),
                                )
                              ],
                            )
                        ),
                      )
                  )
              ),
              kIsWeb ?
              Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                  child: Card(
                      elevation: 4,
                      child: InkWell(
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(width: 5),
                                const Icon(Icons.cookie_outlined),
                                Container(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Cookie Policy', style: Theme.of(context).textTheme.headline6),
                                      Container(height: 12),
                                      Text(cookiesText, style: Theme.of(context).textTheme.caption),
                                    ],
                                  ),
                                )
                              ],
                            )
                        ),
                      )
                  )
              )
                  :
              Container(),
            ]
        ));

  }

  static const String privacyText = '''
We take your privacy very seriously. This is why this app does not communicate any of your data to any server.

Your location is used only on your device and is never sent over the network to a server.

This app uses third-party libraries, like Google Maps to display personalized maps, Google Analytics to trace app usage, and AdMob to serve ads. Their privacy policies can be accessed at their corresponding webpages.

For questions regarding privacy, you can contact us at hello@aspectsense.com.
  ''';

  static const String cookiesText = '''
This web app does not use any third party cookies.

However the app uses third-party libraries, like Google Maps to display personalized maps, and Google Analytics to trace app usage, and AdMob to serve ads. These libraries might use their own cookies.
  ''';
}