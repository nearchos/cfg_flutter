import 'dart:convert';

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
        for (Station station in _syncResponse!.stations) {
          if(!_brands.contains(station.brand)) {
            _brands.check(station.brand);
          }
        }
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
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: _getBrandsListView()
    );
  }

  ListView _getBrandsListView() {
    List<String> allBrands = _brands.unchecked + _brands.checked;
    allBrands.sort();
    return ListView.builder(
        itemCount: allBrands.length,
        itemBuilder: ((context, index) {
          final String brand = allBrands[index];
          return CheckboxListTile(
              value: _brands.isChecked(brand),
              title: Row(
                children: [
                  SizedBox(width: 64, height: 64, child: Padding(padding: const EdgeInsets.all(8), child: Util.imageForBrand(brand))),
                  const SizedBox(width: 10),
                  Text(brand),
                ],
              ),
              onChanged: (bool? checked) => setState(() {
                if(checked != null && checked) {
                  _brands.check(brand);
                } else {
                  _brands.uncheck(brand);
                }
                _saveBrands();
              })
          );
        })
    );
  }
}