import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

class LocationModel extends ChangeNotifier {

  LocationData? _locationData;

  void update(LocationData? locationData) {
    _locationData = locationData;
    notifyListeners();
  }

  LocationData? get locationData => _locationData;
}