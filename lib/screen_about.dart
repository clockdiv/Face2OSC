import 'package:flutter/material.dart';

class ScreenAbout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(right: 0),
      child: Container(
        color: Colors.white,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('About'),
            //ipAdress(),
            Text('Logo Labor + HfS'),
            Text('Funded by...'),
            Text('2023'),
          ],
        ),
      ),
    );
  }
}
