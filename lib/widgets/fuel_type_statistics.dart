import 'package:cfg_flutter/model/fuel_type.dart';
import 'package:cfg_flutter/model/sync_response.dart';

import '../model/price.dart';

class FuelTypeStatistics {

  final FuelType fuelType;
  final int minPrice;
  final int maxPrice;
  final double averagePrice;
  final Map<int,List<String>> pricesToStationCodes;

  FuelTypeStatistics(this.fuelType, this.minPrice, this.maxPrice,
      this.averagePrice, this.pricesToStationCodes);

  @override
  String toString() {
    String s = 'FuelTypeStatistics{fuelType: $fuelType, minPrice: $minPrice, maxPrice: $maxPrice, averagePrice: $averagePrice, pricesToStationCodes: [';
    for (int price in pricesToStationCodes.keys) {
      s += ('$price: ${pricesToStationCodes[price]!.length}, ');
    }
    s += ']';
    return s;
  }

  static FuelTypeStatistics from(SyncResponse? syncResponse, FuelType fuelType) {
    if(syncResponse == null) throw Error();

    int fuelTypeIndex = 0;
    switch(fuelType) {
      case FuelType.petrol95: fuelTypeIndex = 0; break;
      case FuelType.petrol98: fuelTypeIndex = 1; break;
      case FuelType.diesel: fuelTypeIndex = 2; break;
      case FuelType.heating: fuelTypeIndex = 3; break;
      case FuelType.kerosene: fuelTypeIndex = 4;
    }

    int minPrice = 1000000;
    int maxPrice = 0;
    double totalPrice = 0;
    int countPrice = 0;
    Map<int,List<String>> pricesToStationCodes = {};

    for (Price price in syncResponse.prices) {
      if(price.prices[fuelTypeIndex] < minPrice && price.prices[fuelTypeIndex] != 0) { minPrice = price.prices[fuelTypeIndex]; }
      if(price.prices[fuelTypeIndex] > maxPrice) { maxPrice = price.prices[fuelTypeIndex]; }
      totalPrice += price.prices[fuelTypeIndex];
      countPrice++;
      if(!pricesToStationCodes.containsKey(price.prices[fuelTypeIndex])) {
        pricesToStationCodes[price.prices[fuelTypeIndex]] = [];
      }
      pricesToStationCodes[price.prices[fuelTypeIndex]]!.add(price.stationCode);
    }

    return FuelTypeStatistics(fuelType, minPrice, maxPrice, totalPrice/countPrice, pricesToStationCodes);
  }
}