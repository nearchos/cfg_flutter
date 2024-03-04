import 'package:cfg_flutter/view_mode.dart';
import 'package:flutter/material.dart';
import 'package:cfg_flutter/model/fuel_type.dart';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

class Util {

  static const int oneSecondInMilliseconds = 1000;
  static const int oneMinuteInMilliseconds = 60 * oneSecondInMilliseconds;
  static const int oneHourInMilliseconds = 60 * oneMinuteInMilliseconds;
  static const int oneDayInMilliseconds = 24 * oneHourInMilliseconds;

  static String timeInWords(int timeInMilliseconds) {
    if (timeInMilliseconds < 1000) {
      return 'less than a second';
    } else if (timeInMilliseconds < oneMinuteInMilliseconds) {
      return 'less than a minute';
    } else if (timeInMilliseconds < oneHourInMilliseconds) {
      final int numOfMinutes = timeInMilliseconds ~/ oneMinuteInMilliseconds;
      return '$numOfMinutes minute${numOfMinutes > 1 ? "s" : ""}';
    } else if (timeInMilliseconds < oneDayInMilliseconds) {
      final int numOfHours = timeInMilliseconds ~/ oneHourInMilliseconds;
      return '~$numOfHours hour${numOfHours > 1 ? "s" : ""}';
    } else {
      final int numOfDays = timeInMilliseconds ~/ oneDayInMilliseconds;
      return '~$numOfDays day${numOfDays > 1 ? "s" : ""}';
    }
  }

  static String name(FuelType fuelType) {
    switch (fuelType) {
      case FuelType.petrol95:
        return 'Unleaded petrol 95';
      case FuelType.petrol98:
        return 'Unleaded petrol 98';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.heating:
        return 'Heating oil';
      case FuelType.kerosene:
        return 'Kerosene';
    }
  }

  static String nameOfViewMode(ViewMode viewMode) {
    switch(viewMode) {
      case ViewMode.bestValue:
        return 'Best Value';
      case ViewMode.cheapest:
        return 'Cheapest';
      case ViewMode.nearest:
        return 'Nearest';
      case ViewMode.favorites:
        return 'Favorites';
    }
  }

  /// Determine the current position of the device - ask permissions as needed
  ///
  /// When the location services are not enabled or permissions are denied the `Future` will return an error.
  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  static double calculateDistanceInMeters(lat1, lng1, lat2, lng2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${(distanceInMeters ~/ 10 * 10).toStringAsFixed(
          0)}m'; // meters rounded to 10 m
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(
          1)}Km'; // kilometers rounded to 0.1 Km
    }
  }

  static Image imageForBrand(String brand) {
    return Image.asset(imageAssetForBrand(brand));
  }

  static String imageAssetForBrand(String brand) {
    switch(brand) {
      case 'AGIP':
      case 'AG':
        return 'images/agip.png';
      case 'EKO':
      case 'EK':
        return 'images/eko.png';
      case 'ENI':
      case 'EN':
        return 'images/eni.png';
      case 'ESSO':
      case 'ES':
        return 'images/esso.png';
      case 'FILL_N_GO':
      case 'FG':
        return 'images/fill_n_go.png';
      case 'LUKOIL':
      case 'LU':
        return 'images/lukoil.png';
      case 'PETROLINA':
      case 'PE':
        return 'images/petrolina.png';
      case 'SHELL':
      case 'SH':
        return 'images/shell.png';
      case 'STAROIL':
      case 'ST':
        return 'images/staroil.png';
      case 'TOTAL':
      case 'TOTAL_PLUS':
      case 'TO':
        return 'images/total_plus.png';
      default:
        return 'images/independent.png';
    }
  }

  static String getSynchronizeSubtitle(final int lastSynced) {
    if(lastSynced == 0) {
      return 'Not synced yet';
    } else {
      int millisecondsSinceLastSync = DateTime.now().millisecondsSinceEpoch - lastSynced;
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