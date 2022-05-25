import 'package:flutter/material.dart';

class SyncingProgressIndicator extends StatelessWidget {
  const SyncingProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(width: 100, height: 100, child: CircularProgressIndicator()),
            SizedBox(height: 20),
            Text('Fetching data from the Internet ...'),
          ],
        )
    );
  }
}