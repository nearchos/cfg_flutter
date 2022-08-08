import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:cfg_flutter/model/fuel_type.dart';
import 'dart:math';

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

  static Future<Location> requestLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Could not get location service');
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted != PermissionStatus.granted) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Could not get location permission');
      }
    }

    return location;
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
    if ('AGIP' == brand) {
      return 'images/agip.png';
    } else if ('EKO' == brand) {
      return 'images/eko.png';
    } else if ('ENI' == brand) {
      return 'images/eni.png';
    } else if ('ESSO' == brand) {
      return 'images/esso.png';
    } else if ('FILL_N_GO' == brand || 'FILL-N-GO' == brand) {
      return 'images/fill_n_go.png';
    } else if ('LUKOIL' == brand) {
      return 'images/lukoil.png';
    } else if ('PETROLINA' == brand) {
      return 'images/petrolina.png';
    } else if ('SHELL' == brand) {
      return 'images/shell.png';
    } else if ('STAROIL' == brand) {
      return 'images/staroil.png';
    } else if ('TOTAL' == brand) {
      return 'images/total.png';
    } else if ('TOTAL_PLUS' == brand || 'TOTAL-PLUS' == brand) {
      return 'images/total_plus.png';
    } else {
      return 'images/independent.png';
    }
  }
}