import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../model/brands.dart';
import '../model/station.dart';
import '../model/sync_response.dart';
import '../util.dart';

class FilterBrandsPage extends StatefulWidget {

  final String title;

  const FilterBrandsPage({Key? key, required this.title}) : super(key: key);

  @override
  FilterBrandsState createState() => FilterBrandsState();
}

class FilterBrandsState extends State<FilterBrandsPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  SyncResponse? _syncResponse;
  final Map<String,int> _brandPopulation = {};
  late final Brands _brands;

  @override
  void initState() {
    super.initState();

    _loadFromPreferences();
  }

  void _loadFromPreferences() {
    _prefs.then((SharedPreferences prefs) {
      final String? lastRawJson = prefs.getString(
          CyprusFuelGuideApp.keyLastRawJson);
      final String? brandNamesRawJson = prefs.getString(
          CyprusFuelGuideApp.keyBrandNamesRawJson);
      setState(() {
        _brands = brandNamesRawJson != null ? Brands.fromJson(
            jsonDecode(brandNamesRawJson)) : Brands.empty();
        _syncResponse = SyncResponse.fromRawJson(lastRawJson!);
        _brandPopulation.clear();
        for (Station station in _syncResponse!.stations) {
          if(station.brand.trim().isEmpty) {
            station.brand = 'INDEPENDENT';
          }
          if(!_brands.contains(station.brand)) {
            _brands.check(station.brand);
          }
          if(!_brandPopulation.containsKey(station.brand)) {
            _brandPopulation[station.brand] = 1;
          } else {
            _brandPopulation[station.brand] = _brandPopulation[station.brand]! + 1;
          }
        }
        _saveBrands();
      });
    });
  }

  void _saveBrands() {
    _prefs.then((SharedPreferences sharedPreferences) {
      String rawJson = jsonEncode(_brands.toMap());
      sharedPreferences.setString(CyprusFuelGuideApp.keyBrandNamesRawJson, rawJson);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int numOfChecked = _brands.numOfChecked();
    final int numOfUnchecked = _brands.numOfUnchecked();
    String label = numOfUnchecked == 0 ? 'All brands checked'
        :
    '$numOfChecked brands checked ($numOfUnchecked unchecked)';
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 32,
              child: Center(
                  child: Text(label, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))
              ),
            ),
            Expanded(child: _getBrandsListView())
          ],
        )
    );
  }

  ListView _getBrandsListView() {
    List<String> allBrands = _brands.unchecked + _brands.checked;
    allBrands.sort();
    return ListView.separated(
        separatorBuilder: (context, index) => const Divider(color: Colors.brown,),
        itemCount: allBrands.length,
        itemBuilder: ((context, index) {
          final String brand = allBrands[index];
          return CheckboxListTile(
              value: _brands.isChecked(brand),
              title: Row(
                children: [
                  SizedBox(width: 64, height: 64, child: Padding(padding: const EdgeInsets.all(8), child: Util.imageForBrand(brand))),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(brand, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('${_brandPopulation[brand]} stations', style: Theme.of(context).textTheme.bodyMedium)
                    ],
                  ),
                ],
              ),
              onChanged: (bool? checked) => setState(() {
                if(checked != null && checked) {
                  _brands.check(brand);
                } else {
                  if(_brands.numOfChecked() == 1) {
                    // todo show snack that you cannot uncheck all brands
                    debugPrint('you must check at least one brand');
                  } else {
                    _brands.uncheck(brand);
                  }
                }
                _saveBrands();
              })
          );
        })
    );
  }
}