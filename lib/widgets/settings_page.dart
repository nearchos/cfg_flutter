import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../model/range.dart';

class SettingsPage extends StatefulWidget {

  final String title;

  const SettingsPage({Key? key, required this.title}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late Range _selectedRange;
  late bool _showStatisticsInStationView = true;
  late bool _showStatisticsInStationsView = true;

  @override
  void initState() {
    super.initState();

    _loadFromPreferences();
  }

  void _loadFromPreferences() {
    _prefs.then((SharedPreferences prefs) {
      int selectedRange = prefs.getInt(
          CyprusFuelGuideApp.keyRangeForBestValue) ?? RangeExtension.defaultRange.value;
      bool showStatisticsInStationView = prefs.getBool(
          CyprusFuelGuideApp.keyShowStatisticsInStationView) ?? true;
      bool showStatisticsInStationsView = prefs.getBool(
          CyprusFuelGuideApp.keyShowStatisticsInStationsView) ?? true;
      setState(() {
        _selectedRange = RangeExtension.getFromValue(selectedRange);
        _showStatisticsInStationView = showStatisticsInStationView;
        _showStatisticsInStationsView = showStatisticsInStationsView;
      });
    });
  }

  void _saveShowStatisticsInStationsView(bool? value) {
    _prefs.then((SharedPreferences sharedPreferences) {
      setState(() {
        _showStatisticsInStationsView = value ?? true;
      });
      sharedPreferences.setBool(CyprusFuelGuideApp.keyShowStatisticsInStationsView, value ?? true);
    });
  }

  void _saveShowStatisticsInStationView(bool? value) {
    _prefs.then((SharedPreferences sharedPreferences) {
      setState(() {
        _showStatisticsInStationView = value ?? true;
      });
      sharedPreferences.setBool(CyprusFuelGuideApp.keyShowStatisticsInStationView, value ?? true);
    });
  }

  void _saveSelectedRange(final Range? range) {
    _prefs.then((SharedPreferences sharedPreferences) {
      setState(() {
        _selectedRange = range ?? RangeExtension.defaultRange;
      });
      sharedPreferences.setInt(CyprusFuelGuideApp.keyRangeForBestValue, range == null ? RangeExtension.defaultRange.value : range.value);
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
        body: ListView(
          children: [

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
              child: Text('Customization', style: Theme.of(context).textTheme.subtitle2),
            ),
            ListTile(
              leading: Checkbox(
                value: _showStatisticsInStationsView,
                onChanged: (bool? v) => _saveShowStatisticsInStationsView(v),
              ),
              title: const Text('Analytics in lists of stations view'),
              subtitle: Text('Show price statistics in views of lists of stations', style: Theme.of(context).textTheme.bodySmall),
            ),
            ListTile(
              leading: Checkbox(
                value: _showStatisticsInStationView,
                onChanged: (bool? v) => _saveShowStatisticsInStationView(v),
              ),
              title: const Text('Analytics in individual station view'),
              subtitle: Text('Show price statistics in individual station view', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Divider(color: Colors.brown),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
              child: Text('Best value options', style: Theme.of(context).textTheme.subtitle2),
            ),
            ListTile(
                leading: const Icon(Icons.compare_arrows_outlined, color: Colors.brown),
                subtitle: Text('Range for looking up stations in Best value view', style: Theme.of(context).textTheme.bodySmall),
                dense: true,
                title: DropdownButton<Range>(
                  // isDense: true,
                  items: Range.values.map<DropdownMenuItem<Range>>((range) => DropdownMenuItem(
                    value: range,
                    alignment: Alignment.centerLeft,
                    child: Text(range.name),
                  )).toList(),
                  value: _selectedRange,
                  isExpanded: true,
                  underline: const SizedBox(), // hide underline
                  onChanged: (Range? range) => _saveSelectedRange(range),
                )
            ),
            const Divider(color: Colors.brown),

          ],
        )
    );
  }
}