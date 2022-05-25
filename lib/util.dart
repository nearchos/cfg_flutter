import 'package:cfg_flutter/model/fuel_type.dart';

class Util {

  static const int oneSecondInMilliseconds = 1000;
  static const int oneMinuteInMilliseconds = 60 * oneSecondInMilliseconds;
  static const int oneHourInMilliseconds = 60 * oneMinuteInMilliseconds;
  static const int oneDayInMilliseconds = 24 * oneHourInMilliseconds;

  static String timeInWords(int timeInMilliseconds) {
    if(timeInMilliseconds < 1000) {
      return 'less than a second';
    } else if(timeInMilliseconds < oneMinuteInMilliseconds) {
      return 'less than a minute';
    } else if(timeInMilliseconds < oneHourInMilliseconds) {
      final int numOfMinutes = timeInMilliseconds ~/ oneMinuteInMilliseconds;
      return '$numOfMinutes minute${numOfMinutes > 1 ? "s" : ""}';
    } else if(timeInMilliseconds < oneDayInMilliseconds) {
      final int numOfHours = timeInMilliseconds ~/ oneHourInMilliseconds;
      return '~$numOfHours hour${numOfHours > 1 ? "s" : ""}';
    } else {
      final int numOfDays = timeInMilliseconds ~/ oneDayInMilliseconds;
      return '~$numOfDays day${numOfDays > 1 ? "s" : ""}';
    }
  }

  static String name(FuelType fuelType) {
    switch(fuelType) {
      case FuelType.petrol95: return 'Unleaded petrol 95';
      case FuelType.petrol98: return 'Unleaded petrol 98';
      case FuelType.diesel: return 'Diesel';
      case FuelType.heating: return 'Heating oil';
      case FuelType.kerosene: return 'Kerosene';
    }
  }
}