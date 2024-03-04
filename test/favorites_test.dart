import 'dart:convert';

import 'package:cfg_flutter/model/favorites.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String rawJson = '{"codes":["LU037","LU036"]}';

  test('Verifies that the Favorites serialization/deserialization to/from JSON works', () {

    Favorites favorites = Favorites(codes: []);
    expect(favorites.isEmpty(), true);
    expect(favorites.isNotEmpty(), false);
    debugPrint("favorites: $favorites");

    favorites.add("LU037");
    expect(favorites.isEmpty(), false);
    expect(favorites.isNotEmpty(), true);
    debugPrint("favorites: $favorites");

    favorites.add("LU036");
    final String json = jsonEncode(favorites.toMap());
    expect(rawJson==json, true);
    debugPrint("json: $json");

    Favorites favoritesCopy = Favorites.fromJson(jsonDecode(json));
    expect(favoritesCopy.isEmpty(), false);
    expect(favoritesCopy.isNotEmpty(), true);
    expect(favoritesCopy.contains("LU037"), true);
    expect(favoritesCopy.contains("LU036"), true);
    expect(favoritesCopy.contains("LU038"), false);

  });
}