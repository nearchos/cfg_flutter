class Price {
  String stationCode;
  List<int> prices;
  List<int> timestamps;

  Price({required this.stationCode, required this.prices, required this.timestamps});

  factory Price.fromJson(Map<String, dynamic> json) {
    var listOfPrices = json['prices'].map((i) => i as int).toList();
    var listOfTimestamps = json['timestamps'].map((i) => i as int).toList();

    return Price(
        stationCode: json['stationCode'],
        prices: List<int>.from(listOfPrices),
        timestamps: List<int>.from(listOfTimestamps)
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stationCode': stationCode,
      'prices': prices,
      'timestamps': timestamps
    };
  }

  @override
  String toString() {
    return "stationCode: $stationCode, prices: $prices, timestamps: $timestamps";
  }
}