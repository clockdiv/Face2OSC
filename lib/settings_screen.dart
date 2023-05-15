import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(left: 100),
      child: Container(
        color: Colors.white,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings'),
            //ipAdress(),
            Text('Port'),
            Text('Show disabled Tracking Features'),
            Text('Settings'),
          ],
        ),
      ),
    );
  }
}
/*
Widget ipAdress() {
  return Row(
    children: [
      Text('192'),
      Text('168'),
      Text('100'),
      CupertinoPicker(
        itemExtent: 64,
        onSelectedItemChanged: (index) {},
        children: [
          Text('Item 1'),
          Text('Item 2'),
          Text('Item 3'),
          Text('Item 4'),
        ],
      ),
    ],
  );
}
*/