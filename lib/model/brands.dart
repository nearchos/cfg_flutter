class Brands {
  List<String> unchecked;
  List<String> checked;

  Brands({required this.unchecked, required this.checked});

  static Brands empty() => Brands(unchecked: List<String>.empty(growable: true), checked: List<String>.empty(growable: true));

  factory Brands.fromJson(Map<String, dynamic> json) {
    var listOfUnchecked = json['unchecked'].map((i) => i as String).toList();
    var listOfChecked = json['checked'].map((i) => i as String).toList();
    return Brands(
      unchecked: List<String>.from(listOfUnchecked),
      checked: List<String>.from(listOfChecked),
    );
  }

  bool contains(String name) => checked.contains(name) || unchecked.contains(name);
  bool isChecked(String name) => checked.contains(name);
  bool isUnchecked(String name) => unchecked.contains(name);
  void check(String name) {
    unchecked.remove(name);
    checked.add(name);
  }
  void uncheck(String name) {
    unchecked.add(name);
    checked.remove(name);
  }
  bool isEmpty() => unchecked.isEmpty && checked.isEmpty;
  bool isNotEmpty() => unchecked.isNotEmpty || checked.isNotEmpty;
  int length() {
    return unchecked.length + checked.length;
  }
  void clear() {
    checked.clear();
    unchecked.clear();
  }

  Map<String, dynamic> toMap() {
    return { 'checked': checked, 'unchecked': unchecked };
  }

  @override
  String toString() {
    return "checked: $checked -- unchecked: $unchecked";
  }
}