//import 'dart:html';

import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:io';
import 'package:osc/src/message.dart'; // https://github.com/pq/osc
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'screen_about.dart';
import 'screen_settings.dart';

class Face2osc extends StatelessWidget {
  const Face2osc({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return const CupertinoApp(
      title: 'Face2OSC',
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: Face2OSCHomePage(),
    );
  }
}

class Face2OSCHomePage extends StatefulWidget {
  const Face2OSCHomePage({super.key});

  @override
  Face2OSCHomePageState createState() => Face2OSCHomePageState();
}

class Face2OSCHomePageState extends State<Face2OSCHomePage> {
  late ARKitController arkitController;
  ARKitNode? node;

  ARKitNode? leftEye;
  ARKitNode? rightEye;
  // List<ARKitNode?> trackingFeatureGeometries = [];

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _ipAddress;
  late Future<String> _port;
  String oscIpAddress = "", oscPort = "";

  Color _buttonEnableAll = CupertinoColors.systemBlue;
  Color _buttonDisableAll = CupertinoColors.systemGrey;
  final Color _buttonToggleSendingOn = CupertinoColors.systemGreen;
  final Color _buttonToggleSendingOff = CupertinoColors.systemRed;

  // Color _buttonEmpty = CupertinoColors.systemGreen;
  // Color _buttonSettings = CupertinoColors.systemOrange;
  // Color _textBorderIpAdress = CupertinoColors.systemGrey5.withAlpha(0);
  // Color _textBorderPort = CupertinoColors.systemGrey5.withAlpha(0);
  // // bool _showAllFeatures = true;
  // late TextEditingController _ipTextController;
  // late TextEditingController _portTextController;
  // final FocusNode _focusNodeIPTextfield = FocusNode();
  // final FocusNode _focusNodePortTextfield = FocusNode();

  // late InternetAddress destination;
  // late int port;
  RawDatagramSocket? socket;
  bool _isSending = false;

  final Set<String> features = {
    "browDown_L",
    "browDown_R",
    "browInnerUp",
    "browOuterUp_L",
    "browOuterUp_R",
    "cheekPuff",
    "cheekSquint_L",
    "cheekSquint_R",
    "eyeBlink_L",
    "eyeBlink_R",
    "eyeLookDown_L",
    "eyeLookDown_R",
    "eyeLookIn_L",
    "eyeLookIn_R",
    "eyeLookOut_L",
    "eyeLookOut_R",
    "eyeLookUp_L",
    "eyeLookUp_R",
    "eyeSquint_L",
    "eyeSquint_R",
    "eyeWide_L",
    "eyeWide_R",
    "jawForward",
    "jawLeft",
    "jawOpen",
    "jawRight",
    "mouthClose",
    "mouthDimple_L",
    "mouthDimple_R",
    "mouthFrown_L",
    "mouthFrown_R",
    "mouthFunnel",
    "mouthLeft",
    "mouthLowerDown_L",
    "mouthLowerDown_R",
    "mouthPress_L",
    "mouthPress_R",
    "mouthPucker",
    "mouthRight",
    "mouthRollLower",
    "mouthRollUpper",
    "mouthShrugLower",
    "mouthShrugUpper",
    "mouthSmile_L",
    "mouthSmile_R",
    "mouthStretch_L",
    "mouthStretch_R",
    "mouthUpperUp_L",
    "mouthUpperUp_R",
    "noseSneer_L",
    "noseSneer_R",
    "tongueOut"
  };
  Map<String, TrackingFeature> featuresSettings = {};

  Face2OSCHomePageState() {
    // trackingFeatureGeometries = new List<ARKitNode>.empty();
    for (var element in features) {
      featuresSettings[element] = TrackingFeature();
      // trackingFeatureGeometries.add(new ARKitNode());
    }
    featuresSettings["browDown_R"]!.enabled = false;
    // _ipTextController = TextEditingController(text: ('192.168.178.100'));
    // _portTextController = TextEditingController(text: ('4444'));

    // destination = InternetAddress(ScreenSettings().ip);
    // port = int.parse(ScreenSettings().port);
    // developer.log(destination.toString());
    // developer.log(port.toString());
  }

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _readPrefs();
  }

  void _readPrefs() {
    _ipAddress = _prefs.then((SharedPreferences prefs) {
      oscIpAddress = prefs.getString('ip') ?? '192.168.0.100';
      developer.log('Read Prefs in initState, $oscIpAddress');
      return oscIpAddress;
    });
    _port = _prefs.then((SharedPreferences prefs) {
      oscPort = prefs.getString('port') ?? '4444';
      developer.log('Read Prefs in initState, $oscPort');
      return oscPort;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      child: PageView(
        controller: PageController(initialPage: 1),
        physics: const ClampingScrollPhysics(),
        children: [
          const ScreenAbout(),
          screenFacetracking(),
          ScreenSettings(),
        ],
        onPageChanged: (pageIndex) {
          if (pageIndex == 1) {
            _readPrefs();
          }
        },
      ),
    );
  }

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = _handleAddAnchor;
    this.arkitController.onUpdateNodeForAnchor = _handleUpdateAnchor;
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (anchor is! ARKitFaceAnchor) {
      return;
    }
    final material = ARKitMaterial(fillMode: ARKitFillMode.lines);
    anchor.geometry.materials.value = [material];

    node = ARKitNode(geometry: anchor.geometry);
    arkitController.add(node!, parentNodeName: anchor.nodeName);

    // leftEye = _createFeatureGeometry(anchor.leftEyeTransform);
    // arkitController.add(leftEye!, parentNodeName: anchor.nodeName);

    // rightEye = _createEye(anchor.rightEyeTransform);
    // arkitController.add(rightEye!, parentNodeName: anchor.nodeName);

    // featuresSettings.forEach((key, value) {
    //   value.geometry = _createFeatureGeometry(anchor.rightEyeTransform);
    //   arkitController.add(value.geometry, parentNodeName: anchor.nodeName);
    // });
  }

  // ARKitNode _createFeatureGeometry(Matrix4 transform) {
  //   final position = vector.Vector3(
  //     transform.getColumn(3).x,
  //     transform.getColumn(3).y,
  //     transform.getColumn(3).z,
  //   );
  //   final material = ARKitMaterial(
  //     diffuse: ARKitMaterialProperty.color(CupertinoColors.systemBlue),
  //     emission: ARKitMaterialProperty.color(CupertinoColors.systemBlue),
  //   );

  //   // final cube = ARKitBox(materials: [
  //   //   material
  //   // ], width: 0.03, height: 0.03, length: 0.03);

  //   final sphere = ARKitSphere(materials: [
  //     material
  //   ], radius: 0.005);

  //   return ARKitNode(geometry: sphere, position: position);
  // }

  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitFaceAnchor && mounted) {
      //final faceAnchor = anchor;
      arkitController.updateFaceGeometry(node!, anchor.identifier);

      // Update the Geometry of the activated Features

      // _updateGeometry(leftEye!,  anchor.leftEyeTransform,  anchor.blendShapes['eyeBlink_L'] ?? 0);
      // _updateGeometry(rightEye!, anchor.rightEyeTransform, anchor.blendShapes['eyeBlink_R'] ?? 0);

      // anchor.blendShapes.forEach((key, value) {
      //   //developer.log(key);
      //   _toggleGeometry(featuresSettings[key]!.geometry, featuresSettings[key]!.enabled);
      // });

      // Send OSC for all enabled Features

      // RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reuseAddress: true, reusePort: true).then((socket) {
      //   featuresSettings.forEach((key, value) {
      //     if (value.enabled) {
      //       String address = '/$key';
      //       final arguments = <Object>[];
      //       arguments.add(featuresSettings[key]!.weight);
      //       final message = OSCMessage(address, arguments: arguments);
      //       final bytes = message.toBytes();
      //       socket.send(bytes, destination, port);
      //     }
      //   });
      // });

      if (socket != null && _isSending) {
        featuresSettings.forEach((key, value) {
          if (value.enabled) {
            String address = '/$key';
            final arguments = <Object>[];
            arguments.add(featuresSettings[key]!.weight);
            final message = OSCMessage(address, arguments: arguments);
            final bytes = message.toBytes();
            //socket?.send(bytes, destination, port);
            // socket?.send(bytes, InternetAddress(ScreenSettings().ip),
            //     int.parse(ScreenSettings().port));
            socket?.send(
                bytes, InternetAddress(oscIpAddress), int.parse(oscPort));
          }
        });
      }

      // Set State for the Featuresettings-List
      setState(() {
        featuresSettings.forEach((key, value) {
          featuresSettings[key]!.weight = anchor.blendShapes[key] ?? 0;
        });
      });
    }
  }

  // void _updateGeometry(ARKitNode node, Matrix4 transform, double blink) {
  //   final scale = vector.Vector3(1, 1 - blink, 1);
  //   node.scale = scale;
  // }

  // void _toggleGeometry(ARKitNode node, bool enabled) {
  //   node.scale = enabled ? vector.Vector3.all(1) : vector.Vector3.all(1);
  // }

  void _toggleOSCSocket() async {
    setState(() {
      _isSending = !_isSending;
    });

    if (_isSending) {
      if (socket != null) socket?.close();

      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
    } else {
      socket?.close();
      developer.log("socket closed.");
    }
  }

  Widget screenFacetracking() {
    return Center(
      child: Column(
        children: [
          // ----------- 4. Stacked ARKitSceneView with PAGEVIEW. Pageview has an empty Container and the SettingsScreen
          Expanded(
            flex: 5,
            // child: Container(
            //   child: Text("hello world 1"),
            //   color: CupertinoColors.activeBlue,
            //   alignment: Alignment.center,
            // ),
            child: ClipRRect(
              //borderRadius: BorderRadius.all(Radius.circular(16)),
              child: Container(
                alignment: Alignment.center,
                color: CupertinoColors.activeGreen,
                //child: Text("green area"),
                child: ARKitSceneView(
                  configuration: ARKitConfiguration.faceTracking,
                  onARKitViewCreated: onARKitViewCreated,
                ),
                // child: Stack(
                //   children: [
                //     ARKitSceneView(
                //       configuration: ARKitConfiguration.faceTracking,
                //       onARKitViewCreated: onARKitViewCreated,
                //     ),
                //     PageView(
                //       controller: PageController(initialPage: 1),
                //       physics: const ClampingScrollPhysics(),
                //       children: [
                //         ScreenAbout(),
                //         Container(),
                //         ScreenSettings(),
                //       ],
                //     ),
                //   ],
                // ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: blendshapeWidgetList(featuresSettings),
          ),
        ],
      ),
    );
  }

  Widget blendshapeWidgetList(Map<String, TrackingFeature> featuresSettings) {
    return CustomScrollView(
      semanticChildCount: featuresSettings.length,
      slivers: <Widget>[
        // const CupertinoSliverNavigationBar(
        //   largeTitle: Text('Blendshape_Row_Items'),
        // ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              CupertinoListSection.insetGrouped(
                footer: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  // child: FutureBuilder<String>(
                  //   future: _ipAddress,
                  //   builder: (BuildContext context,
                  //       AsyncSnapshot<String> snapshot) {
                  //     switch (snapshot.connectionState) {
                  //       case ConnectionState.none:
                  //       case ConnectionState.waiting:
                  //         return const CircularProgressIndicator();
                  //       case ConnectionState.active:
                  //       case ConnectionState.done:
                  //         if (snapshot.hasError) {
                  //           return const Text(
                  //             "Could not read preferences for IP-Address and Port",
                  //             style: TextStyle(
                  //               fontSize: 10,
                  //               color: CupertinoColors.systemGrey,
                  //             ),
                  //           );
                  //         } else {
                  //           return Text(
                  //             "Only enabled tracking features are sent to the receiver via OSC.\n\nIP-Address of the Receiver: ${snapshot.data}\nPort of the Receiver: _____",
                  //             style: const TextStyle(
                  //               fontSize: 10,
                  //               color: CupertinoColors.systemGrey,
                  //             ),
                  //           );
                  //         }
                  //     }
                  //   },
                  // )
                  child: Text(
                    "Only enabled tracking features are sent to the receiver via OSC.\n\nIP-Address of the Receiver: $oscIpAddress\nPort of the Receiver: $oscPort",
                    // "Only enabled tracking features are sent to the receiver via OSC",
                    //style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                hasLeading: true,
                children: [
                  /* ------------------------------------------------------- */
                  /* --- Buttons on top of List to controll all Features --- */
                  // --- Enable / Disable all
                  /* ------------------------------------------------------- */
                  SafeArea(
                    top: false,
                    bottom: false,
                    left: false,
                    right: false,
                    minimum: const EdgeInsets.only(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      right: 0,
                    ),
                    child: Row(
                      children: [
                        /* Button Enable All */
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTapDown: (TapDownDetails details) {
                              setState(() {
                                _buttonEnableAll =
                                    CupertinoColors.systemBlue.darkColor;
                              });
                            },
                            onTapUp: (TapUpDetails details) {
                              setState(() {
                                _buttonEnableAll = CupertinoColors.systemBlue;
                                for (int i = 0;
                                    i < featuresSettings.length;
                                    i++) {
                                  featuresSettings.values.elementAt(i).enabled =
                                      true;
                                }
                              });
                            },
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              color: _buttonEnableAll,
                              child: const Text(
                                "Enable all",
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 14,
                                  fontFamily: '.SF UI Text',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        /* Button Disable All */
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTapDown: (TapDownDetails details) {
                              setState(() {
                                _buttonDisableAll =
                                    CupertinoColors.systemGrey.darkColor;
                              });
                            },
                            onTapUp: (TapUpDetails details) {
                              setState(() {
                                _buttonDisableAll = CupertinoColors.systemGrey;
                                for (int i = 0;
                                    i < featuresSettings.length;
                                    i++) {
                                  featuresSettings.values.elementAt(i).enabled =
                                      false;
                                }
                              });
                            },
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              color: _buttonDisableAll,
                              child: const Text(
                                "Disable all",
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 14,
                                  fontFamily: '.SF UI Text',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        /* Button StartStop Tracking */
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTapDown: (TapDownDetails details) {
                              setState(() {
                                //_buttonToggleSending = _buttonToggleSending.;
                              });
                            },
                            onTapUp: (TapUpDetails details) {
                              _toggleOSCSocket();
                            },
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              color: _isSending
                                  ? _buttonToggleSendingOff
                                  : _buttonToggleSendingOn,
                              child: Text(
                                _isSending ? "Stop" : "Start",
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 14,
                                  fontFamily: '.SF UI Text',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                hasLeading: true,
                /* ------------------------------------------------------- */
                /* --- List with all Tracking features ------------------- */
                /* ------------------------------------------------------- */
                children: [
                  for (int i = 0; i < featuresSettings.length; i++)
                    Slidable(
                      closeOnScroll: false,
                      endActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (BuildContext context) {
                              setState(
                                () {
                                  featuresSettings.values.elementAt(i).enabled =
                                      !featuresSettings.values
                                          .elementAt(i)
                                          .enabled;
                                },
                              );
                            },
                            backgroundColor: CupertinoColors.systemBlue,
                            foregroundColor: CupertinoColors.white,
                            label: featuresSettings.values.elementAt(i).enabled
                                ? 'Disable'
                                : 'Enable',
                          )
                        ],
                      ),
                      child: blendShapeRowItem(
                          featuresSettings.keys.elementAt(i),
                          featuresSettings.values.elementAt(i).weight,
                          featuresSettings.values.elementAt(i).enabled,
                          i),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget blendShapeRowItem(
      String name, double weight, bool enabled, int index) {
    return SafeArea(
      top: false,
      bottom: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(
        left: 0,
        top: 0,
        bottom: 0,
        right: 8,
      ),
      child: CupertinoListTile(
        padding: EdgeInsets.zero,
        leading: GestureDetector(
          onTap: () {
            setState(
              () {
                featuresSettings.values.elementAt(index).enabled =
                    !featuresSettings.values.elementAt(index).enabled;
                // developer.log("changed");
              },
            );
          },
          child: Container(
            color: CupertinoColors.white.withAlpha(0),
            width: 64,
            height: 64,
            child: Icon(
              CupertinoIcons.circle_filled,
              semanticLabel: 'Enable/Disable Feature',
              size: 12,
              color: enabled
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.inactiveGray,
            ),
          ),
        ),
        leadingSize: 64,
        leadingToTitle: 0,
        title: Text(name),
        // subtitle: Text(valueToString(weight)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 24, child: Text(valueToString(weight))),
            SizedBox(
              width: weight * 100,
              height: 2,
              child: Container(
                color: CupertinoColors.systemGrey3,
              ),
            ),
          ],
        ),
      ),
    );
  }

/*
  Widget screenSettings() {
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
                    },
                    onTapOutside: (e) {
                      _textBorderIpAdress = CupertinoColors.systemGrey5.withAlpha(0);
                      if (_focusNodeIPTextfield.hasFocus) {
                        _focusNodeIPTextfield.unfocus();
                      }
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
  */
}

class TrackingFeature {
  double weight = 0.0;
  bool enabled = true;
  late ARKitNode geometry;

  TrackingFeature();
}

String valueToString(double n) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
}

Future<String> getWifiIP() async {
  for (var interface
      in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    developer.log('== Interface: ${interface.name} ==');
    for (var addr in interface.addresses) {
//      return '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}';

      developer.log(
          '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
    }
  }

  return 'Unknown';
}
