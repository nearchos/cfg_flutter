import 'package:cfg_flutter/keys.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

// const baseUrl = 'demogaej.appspot.com';
const baseUrl = 'cyprusfuelguide.appspot.com';

Future<String> sync({int from = 0}) async {

  // Uri uri = Uri.https(baseUrl, 'cfg/sync', {'key': flutterMagic, 'from': '$from'});
  Uri uri = Uri.https(baseUrl, 'api/sync', {'key': flutterMagic, 'from': '$from'});

  final Response response = await http.get(uri);
  debugPrint('Got response');

  if (response.statusCode == 200) {
    // If the server returned a 200 OK response, then parse it as JSON
    return response.body;
  } else {
    // If the server did not return a 200 OK response, then throw an exception.
    throw Exception('Failed to load list of treasure hunts');
  }
}