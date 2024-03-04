import 'package:http/http.dart' as http;
import 'package:http/http.dart';

const baseUrl = 'unibackend.appspot.com';

const flutterMagic = 'e9407a6b-d0fc-4aba-bc7d-4cf97c824765';

Future<String> sync({int from = 0}) async {

  Uri uri = Uri.https(baseUrl, 'cfg/cors-sync', {'key': flutterMagic});

  final Response response = await http.get(uri);

  if (response.statusCode == 200) {
    // If the server returned a 200 OK response, then parse it as JSON
    return response.body;
  } else {
    // If the server did not return a 200 OK response, then throw an exception.
    throw Exception('Failed to load list of treasure hunts');
  }
}