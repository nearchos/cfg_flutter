enum Range {
  range_001km,
  range_002km,
  range_005km,
  range_010km,
  range_020km,
  range_100km,
}

extension RangeExtension on Range {

  static Range defaultRange = Range.range_010km; // default is Range.range_010km

  static Range getFromValue(int value) {
    switch(value) {
      case 1:
        return Range.range_001km;
      case 2:
        return Range.range_002km;
      case 5:
        return Range.range_005km;
      case 10:
        return Range.range_010km;
      case 20:
        return Range.range_020km;
      case 100:
        return Range.range_100km;
      default:
        return defaultRange;
    }
  }

  int get value {
    switch(this) {
      case Range.range_001km:
        return 1;
      case Range.range_002km:
        return 2;
      case Range.range_005km:
        return 5;
      case Range.range_010km:
        return 10;
      case Range.range_020km:
        return 20;
      case Range.range_100km:
        return 100;
      default:
        return defaultRange.value;
    }
  }

  String get name {
    switch(this) {
      case Range.range_001km:
        return '1 Km';
      case Range.range_002km:
        return '2 Km';
      case Range.range_005km:
        return '5 Km';
      case Range.range_010km:
        return '10 Km';
      case Range.range_020km:
        return '20 Km';
      case Range.range_100km:
        return '100 Km';
      default:
        return defaultRange.name;
    }
  }
}