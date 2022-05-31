import 'package:flutter/material.dart';

import '../model/fuel_type.dart';
import '../view_mode.dart';

class InfoTileWidget extends StatelessWidget {
  const InfoTileWidget({Key? key, required this.fuelType, required this.viewMode}) : super(key: key);

  final FuelType fuelType;
  final ViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    String label = ' ⛽ ';
    switch(viewMode) {
      case ViewMode.overview: label += 'Overview'; break;
      case ViewMode.cheapest: label += 'Cheapest'; break;
      case ViewMode.nearest: label += 'Nearest'; break;
      case ViewMode.favorites: label += 'Favorites'; break;
    }
    label += ' · ';
    switch(fuelType) {
      case FuelType.petrol95: label += 'Unleaded Petrol 95'; break;
      case FuelType.petrol98: label += 'Unleaded Petrol 98'; break;
      case FuelType.diesel: label += 'Diesel'; break;
      case FuelType.heating: label += 'Heating'; break;
      case FuelType.kerosene: label += 'Kerosene'; break;
    }

    return Container(
      color: Colors.grey[300],
      child: SizedBox(
        height: 32,
        child: Center(
            child: Text(label, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))
        ),
      ),
    );
  }
}