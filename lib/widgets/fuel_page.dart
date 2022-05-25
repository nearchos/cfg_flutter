import 'package:cfg_flutter/model/sync_response.dart';
import 'package:cfg_flutter/widgets/fuel_type_statistics.dart';
import 'package:flutter/material.dart';
import '../model/fuel_type.dart';
import '../model/station.dart';
import '../util.dart';

class FuelPage extends StatefulWidget {
  const FuelPage({Key? key, required this.fuelType, required this.syncResponse}) : super(key: key);

  final FuelType fuelType;
  final SyncResponse? syncResponse;

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {

  @override
  Widget build(BuildContext context) {
    return widget.syncResponse == null
        ?
    const Text('No data')
        :
    _getListView(widget.syncResponse!, widget.fuelType);
  }

  Widget _getListView(SyncResponse syncResponse, FuelType fuelType) {
    FuelTypeStatistics fuelTypeStatistics = FuelTypeStatistics.from(syncResponse, fuelType);
    final int minPrice = fuelTypeStatistics.minPrice;
    final int maxPrice = fuelTypeStatistics.maxPrice;
    final double avgPrice = fuelTypeStatistics.averagePrice;
    final int diff = (avgPrice - minPrice).round();
    final int numOfBestPriceStations = fuelTypeStatistics.pricesToStationCodes[minPrice]!.length;
    final int nearestStationDistance = 12300;//todo
    final int nearestStationPrice = 1230;//todo
    final int numOfFavorites = 4; // todo
    return ListView(
      children: [
        _getTitleWithIconCard(const Icon(Icons.local_gas_station), Util.name(fuelType)),
        _getCard(const Icon(Icons.check, color: Colors.green), 'Lowest price €${minPrice/1000}', 'This is ${diff/10}¢ cheaper than the average, available in $numOfBestPriceStations station${numOfBestPriceStations > 1 ? "s" : ""}', _expand, []),
        _getCard(const Icon(Icons.near_me_outlined, color: Colors.green), 'Nearest station ${nearestStationDistance/1000} Km away', 'Prices from €${nearestStationPrice/1000}', _expand, []),
        _getCard(const Icon(Icons.star_border_outlined, color: Colors.green), 'Best price €${1234/1000} in favorites', 'Comparing prices from ${numOfFavorites} favorites', _expand, []),
        Text('${widget.syncResponse == null ? 'null' : widget.syncResponse}'),
        Text('${widget.syncResponse == null ? 'null' : widget.syncResponse!.stations[0]}'),
        Text('456'),
        Text('${widget.syncResponse == null ? 'null' : FuelTypeStatistics.from(widget.syncResponse, widget.fuelType)}'),
      ],
    );
  }

  Widget _getTitleWithIconCard(Widget icon, String title) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: Card(
            elevation: 4,
            child: InkWell(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(width: 5),
                      icon,
                      Container(width: 15),
                      Text(title, style: Theme.of(context).textTheme.headline6),
                    ],
                  )
              ),
            )
        )
    );
  }

  Widget _getCard(Widget icon, String title, String subtitle, Function callback, dynamic callbackParameter) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: Card(
            elevation: 4,
            child: InkWell(
              onTap: () => callback(callbackParameter),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(width: 5),
                      icon,
                      Container(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Theme.of(context).textTheme.headline6),
                            Container(height: 12),
                            Text(subtitle, style: Theme.of(context).textTheme.caption),
                          ],
                        ),
                      )
                    ],
                  )
              ),
            )
        )
    );
  }

  void _expand(List<Station> stations) async {
    //todo
  }

}