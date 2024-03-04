import 'package:flutter/foundation.dart';

import 'coordinates.dart';

class LocationModel extends ChangeNotifier {

  Coordinates _coordinates = Coordinates(35.1856, 33.3823); // hardcoded Nicosia coordinates as default

  void update(Coordinates coordinates) {
    _coordinates = coordinates;
    notifyListeners();
  }

  Coordinates get coordinates => _coordinates;
  double get latitude => _coordinates.latitude;
  double get longitude => _coordinates.longitude;
}