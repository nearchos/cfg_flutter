class Offline {
  String stationCode;
  bool offline;

  Offline({required this.stationCode, required this.offline});

  factory Offline.fromJson(Map<String, dynamic> json) {
    return Offline(
        stationCode: json['stationCode'],
        offline: json['offline']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stationCode': stationCode,
      'offline': offline
    };
  }

  @override
  String toString() {
    return "stationCode: $stationCode, offline: $offline";
  }
}