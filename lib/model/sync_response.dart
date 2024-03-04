import 'dart:convert';

import 'package:cfg_flutter/model/price.dart';
import 'package:cfg_flutter/model/station.dart';
import 'package:cfg_flutter/model/offline.dart';

class SyncResponse {

  String status;
  int from;
  List<Station> stations;
  List<Station> removedStations;
  List<Offline> offlines;
  List<Price> prices;
  int numberOfModifications;
  int processedInMilliseconds;
  int lastUpdated;

  SyncResponse({required this.status, required this.from, required this.stations,
    required this.removedStations, required this.offlines, required this.prices,
    required this.numberOfModifications, required this.processedInMilliseconds,
    required this.lastUpdated});

  factory SyncResponse.fromRawJson(String rawJson) {
    return SyncResponse.fromJson(jsonDecode(rawJson));
  }

  factory SyncResponse.fromJson(Map<String, dynamic> json) {

    var listOfStations = json['stations'].map((i) => Station.fromJson(i)).toList();
    var listOfRemovedStations = json['removedStations'] != null ? json['removedStations'].map((i) => Station.fromJson(i)).toList() : [];
    var listOfOfflines = json['offlines'] != null ? json['offlines'].map((i) => Offline.fromJson(i)).toList() : [];
    var listOfPrices = json['prices'].map((i) => Price.fromJson(i)).toList();

    return SyncResponse(
        status: json['status'],
        from: json['from'] ?? 0,
        stations: List<Station>.from(listOfStations),
        removedStations: List<Station>.from(listOfRemovedStations),
        offlines: List<Offline>.from(listOfOfflines),
        prices: List<Price>.from(listOfPrices),
        numberOfModifications: json['numberOfModifications'] ?? 0,
        processedInMilliseconds: json['processedInMilliseconds'],
        lastUpdated: json['lastUpdated']
    );
  }

  @override
  String toString() { // for debug purposes
    return 'status: $status, from: $from, num of stations: ${stations.length},'
        ' num of removed stations: ${removedStations.length}, num of offlines: '
        '${offlines.length}, num of prices: ${prices.length}, '
        'numberOfModifications: $numberOfModifications, '
        'processedInMilliseconds: $processedInMilliseconds, lastUpdated: $lastUpdated';
  }
}