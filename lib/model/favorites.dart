class Favorites {
  List<String> codes;

  Favorites({required this.codes});

  static Favorites empty() => Favorites(codes: List<String>.empty(growable: true));

  factory Favorites.fromJson(Map<String, dynamic> json) {
    var listOfCodes = json['codes'].map((i) => i as String).toList();
    return Favorites(
        codes: List<String>.from(listOfCodes)
    );
  }

  bool contains(String code) => codes.contains(code);
  void add(String code) => codes.add(code);
  bool remove(String code) => codes.remove(code);
  bool isEmpty() => codes.isEmpty;
  bool isNotEmpty() => codes.isNotEmpty;
  int length() {
    return codes.length;
  }

  Map<String, dynamic> toMap() {
    return { 'codes': codes };
  }

  @override
  String toString() {
    return "favorites: $codes";
  }
}