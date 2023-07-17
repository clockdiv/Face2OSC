import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';

class ScreenSettings extends StatefulWidget {
  ScreenSettings({super.key});

  String _ipAdress = "192.168.222.222";
  String _port = "3333";

  void set ip(String ip) {
    _ipAdress = ip;
    developer.log("new ip is: $_ipAdress");
  }

  void set port(String port) {
    _port = port;
  }

  String get ip => _ipAdress;
  String get port => _port;

  @override
  State<ScreenSettings> createState() {
    return _ScreenSettingsState();
  }
}

class _ScreenSettingsState extends State<ScreenSettings> {
  Color _textBorderIpAdress = CupertinoColors.systemGrey5.withAlpha(0);
  Color _textBorderPort = CupertinoColors.systemGrey5.withAlpha(0);

  late TextEditingController _ipTextController = TextEditingController(text: (widget.ip));
  late TextEditingController _portTextController = TextEditingController(text: (widget.port));

  // bool _showAllFeatures = true;
  final FocusNode _focusNodeIPTextfield = FocusNode();
  final FocusNode _focusNodePortTextfield = FocusNode();

  // _ScreenSettingsState() {
  //   _ipTextController = TextEditingController(text: (widget.ip));
  //   _portTextController = TextEditingController(text: (widget.port));
  // }

  void setIpAddress() {
    developer.log("setting ip address...");
    setState(() {
      widget.ip = "111.111.222.333";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.systemGrey6,
      padding: const EdgeInsets.only(
        top: 96,
        left: 0,
        right: 0,
        bottom: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        //mainAxisAlignment: MainAxisAlignment.,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
            ),
            child: Text(
              'Settings',
              style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
            ),
          ),
          /* ------------------------------------------------------- */
          /* --- App Settings ---------------------------------- */
          /* ------------------------------------------------------- */
          // CupertinoListSection.insetGrouped(
          //   // header: Text(
          //   //   'APP SETTINGS',
          //   // ),
          //   children: [
          //     //SafeArea(
          //     CupertinoListTile(
          //       padding: const EdgeInsets.all(16),
          //       title: Text('Show all Tracking Features'),
          //       subtitle: Text('Shows also disabled tracking features in the list.'),
          //       trailing: CupertinoSwitch(
          //         value: _showAllFeatures,
          //         onChanged: (value) {
          //           setState(() {
          //             _showAllFeatures = value;
          //           });
          //         },
          //       ),
          //     ),
          //     // ),
          //   ],
          // ),

          /* ------------------------------------------------------- */
          /* --- Network Settings ---------------------------------- */
          /* ------------------------------------------------------- */
          CupertinoListSection.insetGrouped(
            // header: Text(
            //   'NETWORK SETTINGS',
            // ),

            children: [
              CupertinoListTile(
                padding: const EdgeInsets.all(16),
                title: const Text('IP-Address'),
                subtitle: const Text('IP of the Receiver.'),
                trailing: SizedBox(
                  width: 140,
                  child: CupertinoTextField(
                    focusNode: _focusNodeIPTextfield,
                    // decoration: BoxDecoration(borderRadius: BorderRadius.circular(1.0)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _textBorderIpAdress),
                    ),
                    controller: _ipTextController,
                    keyboardType: TextInputType.datetime,
                    textAlign: TextAlign.right,
                    maxLength: 15,
                    onTap: () {
                      setState(() {
                        _textBorderIpAdress = CupertinoColors.systemGrey5;
                        _textBorderPort = CupertinoColors.systemGrey5.withAlpha(0);
                      });
                    },
                    onSubmitted: (ipadress) {
                      setState(() {
                        _textBorderIpAdress = CupertinoColors.systemGrey5.withAlpha(0);
                      });
                      setIpAddress();
                    },
                    onTapOutside: (e) {
                      _textBorderIpAdress = CupertinoColors.systemGrey5.withAlpha(0);
                      if (_focusNodeIPTextfield.hasFocus) {
                        _focusNodeIPTextfield.unfocus();
                      }
                      setIpAddress();
                    },
                  ),
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.all(16),
                title: const Text('Port'),
                subtitle: const Text('Port of the Receiver.'),
                trailing: SizedBox(
                  width: 140,
                  child: CupertinoTextField(
                    focusNode: _focusNodePortTextfield,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _textBorderPort),
                    ),
                    controller: _portTextController,
                    keyboardType: TextInputType.datetime,
                    textAlign: TextAlign.right,
                    maxLength: 5,
                    onTap: () {
                      setState(() {
                        _textBorderPort = CupertinoColors.systemGrey5;
                        _textBorderIpAdress = CupertinoColors.systemGrey5.withAlpha(0);
                      });
                    },
                    onSubmitted: (ipadress) {
                      setState(() {
                        _textBorderPort = CupertinoColors.systemGrey5.withAlpha(0);
                      });
                    },
                    onTapOutside: (e) {
                      _textBorderPort = CupertinoColors.systemGrey5.withAlpha(0);
                      if (_focusNodePortTextfield.hasFocus) {
                        _focusNodePortTextfield.unfocus();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
