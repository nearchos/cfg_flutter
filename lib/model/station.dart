class Station {
  String code;
  String brand;
  String name;
  String telNo;
  String address;
  String district;
  String city;
  double lat;
  double lng;

  Station({required this.code, required this.brand, required this.name,
    required this.telNo, required this.address, required this.district,
    required this.city, required this.lat, required this.lng});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
        code: json['code'],
        brand: json['brand'],
        name: json['name'],
        telNo: json['telNo'],
        address: json['address'],
        district: json['district'],
        city: json['city'],
        lat: json['lat'],
        lng: json['lng']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'brand': brand,
      'name': name,
      'telNo': telNo,
      'address': address,
      'district': district,
      'city': city,
      'lat': lat,
      'lng': lng
    };
  }

  String get fullAddress => '$address, $district, $city';
  String get coordinates => '$lat,$lng';

  @override
  String toString() {
    return "code: $code, brand: $brand, name: $name, telNo: $telNo, address: $address, district: $district, city: $city @ ($lat,$lng)";
  }
}