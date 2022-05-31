import 'package:flutter/material.dart';

class UnknownLocationCard extends StatelessWidget {
  const UnknownLocationCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      const Icon(Icons.near_me_outlined, color: Colors.grey),
                      Container(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unknown location', style: Theme.of(context).textTheme.titleMedium),
                            Container(height: 12),
                            Text('Make sure your location service is turned on', style: Theme.of(context).textTheme.caption),
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
}