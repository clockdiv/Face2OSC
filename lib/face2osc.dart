//import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:io';
import 'package:osc/src/convert.dart';
import 'package:osc/src/message.dart'; // https://github.com/pq/osc
import 'package:osc/src/io.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class face2osc extends StatelessWidget {
  const face2osc({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);

    return CupertinoApp(
      title: 'Face2OSC',
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: Face2OSCHomePage(),
    );
  }
}

class Face2OSCHomePage extends StatefulWidget {
  @override
  _Face2OSCHomePageState createState() => _Face2OSCHomePageState();
}

class trackingFeature {
  double weight = 0.0;
  bool enabled = true;
  late ARKitNode geometry;

  trackingFeature() {
    //weight = 0.1;
    //enabled = true;
  }
}

class _Face2OSCHomePageState extends State<Face2OSCHomePage> {
  late ARKitController arkitController;
  ARKitNode? node;

  ARKitNode? leftEye;
  ARKitNode? rightEye;
  // List<ARKitNode?> trackingFeatureGeometries = [];

  Color _buttonEnableAll = CupertinoColors.systemBlue;
  Color _buttonDisableAll = CupertinoColors.systemGrey;
  // Color _buttonEmpty = CupertinoColors.systemGreen;
  // Color _buttonSettings = CupertinoColors.systemOrange;

  Color _textBorderIpAdress = CupertinoColors.systemGrey5.withAlpha(0);
  Color _textBorderPort = CupertinoColors.systemGrey5.withAlpha(0);

  // bool _showAllFeatures = true;
  late TextEditingController _ipTextController;
  late TextEditingController _portTextController;
  final FocusNode _focusNodeIPTextfield = FocusNode();
  final FocusNode _focusNodePortTextfield = FocusNode();

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
  Map<String, trackingFeature> featuresSettings = {};

  _Face2OSCHomePageState() {
    // trackingFeatureGeometries = new List<ARKitNode>.empty();
    features.forEach((element) {
      featuresSettings[element] = new trackingFeature();
      // trackingFeatureGeometries.add(new ARKitNode());
    });
    featuresSettings["browDown_R"]!.enabled = false;
    _ipTextController = TextEditingController(text: ('192.168.1.100'));
    _portTextController = TextEditingController(text: ('4444'));
  }

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      child: PageView(
        controller: PageController(initialPage: 1),
        physics: const ClampingScrollPhysics(),
        children: [
          Screen_About(),
          Screen_Facetracking(),
          Screen_Settings(),
        ],
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
    anchor.geometry.materials.value = [
      material
    ];

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

    developer.log(anchor.blendShapes.length.toString());
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
      InternetAddress destination = InternetAddress(_ipTextController.text);
      int port = int.parse(_portTextController.text);
      developer.log(port.toString());

      featuresSettings.forEach((key, value) {
        if (value.enabled) {
          String address = '/$key';
          final arguments = <Object>[];
          arguments.add(featuresSettings[key]!.weight);
          final message = OSCMessage(address, arguments: arguments);
          RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
            final bytes = message.toBytes();
            socket.send(bytes, destination, port);
          });
        }
      });

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

  Widget Screen_Facetracking() {
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
            child: BlendshapeWidgetList(featuresSettings),
          ),
        ],
      ),
    );
  }

  Widget BlendshapeWidgetList(Map<String, trackingFeature> featuresSettings) {
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
                  child: Text(
                    "Only enabled tracking features are sent to the receiver via OSC.\n" + "\nIP-Address of the Receiver: " + _ipTextController.text.toString() + "\nPort of the Receiver: " + _portTextController.text.toString(),
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
                                _buttonEnableAll = CupertinoColors.systemBlue.darkColor;
                              });
                            },
                            onTapUp: (TapUpDetails details) {
                              setState(() {
                                _buttonEnableAll = CupertinoColors.systemBlue;
                                for (int i = 0; i < featuresSettings.length; i++) {
                                  featuresSettings.values.elementAt(i).enabled = true;
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
                                _buttonDisableAll = CupertinoColors.systemGrey.darkColor;
                              });
                            },
                            onTapUp: (TapUpDetails details) {
                              setState(() {
                                _buttonDisableAll = CupertinoColors.systemGrey;
                                for (int i = 0; i < featuresSettings.length; i++) {
                                  featuresSettings.values.elementAt(i).enabled = false;
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
                        /* Button Empty Button */
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
                                  featuresSettings.values.elementAt(i).enabled = !featuresSettings.values.elementAt(i).enabled;
                                },
                              );
                            },
                            backgroundColor: CupertinoColors.systemBlue,
                            foregroundColor: CupertinoColors.white,
                            label: featuresSettings.values.elementAt(i).enabled ? 'Disable' : 'Enable',
                          )
                        ],
                      ),
                      child: BlendShape_Row_Item(featuresSettings.keys.elementAt(i), featuresSettings.values.elementAt(i).weight, featuresSettings.values.elementAt(i).enabled, i),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget BlendShape_Row_Item(String name, double weight, bool enabled, int index) {
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
                featuresSettings.values.elementAt(index).enabled = !featuresSettings.values.elementAt(index).enabled;
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
              size: 8,
              color: enabled ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
            ),
          ),
        ),
        leadingSize: 64,
        leadingToTitle: 0,
        title: Text(name),
        subtitle: Text(valueToString(weight)),
      ),
    );
  }

  Widget Screen_Settings() {
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
                trailing: Container(
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
                trailing: Container(
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

  Widget Screen_About() {
    return Container(
      color: CupertinoColors.systemGrey6,
      padding: const EdgeInsets.only(
        top: 96,
        left: 16,
        right: 16,
        bottom: 32,
      ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //mainAxisAlignment: MainAxisAlignment.,

            children: [
              Text(
                'About',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                child: Container(
                  color: CupertinoColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        //          const SizedBox(height: 20),
                        const Text(
                          'This app was developed as part of the "Digital Lab" at the School for Performing Arts "Ernst Busch" in Berlin/Germany, which was funded by "Stiftung Innovation in der Hochschullehre".',
                          style: TextStyle(color: CupertinoColors.black, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Although there are several similar apps in the App Store, we wanted to have a simple face tracking app that sends tracking features (blendshapes) to a network device via OSC. We use it to control software synthesizers, animations in Blender or physical actuators like servo motors in puppets.',
                          style: TextStyle(color: CupertinoColors.black, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              SizedBox(
                // color: CupertinoColors.activeBlue,
                width: double.infinity,
                child: SvgPicture.asset('assets/logos/Logo_ErnstBusch.svg', width: 180),
              ),
              const SizedBox(height: 40),
              SizedBox(
                // color: CupertinoColors.activeGreen,
                width: double.infinity,
                child: SvgPicture.asset('assets/logos/Logo_LaborFuerDigitalitaet.svg', width: 80),
              ),
              const SizedBox(height: 40),
              SizedBox(
                // color: CupertinoColors.activeOrange,
                width: double.infinity,
                child: SvgPicture.asset('assets/logos/Logo_StiftungHochschullehre.svg', width: 160),
              ),
              const SizedBox(height: 40),
              const Text(
                'MIT License, Copyright (c) 2023',
                style: TextStyle(color: CupertinoColors.black, fontSize: 12),
              ),
              const Text(
                'Hochschule für Schauspielkunst Ernst Busch',
                style: TextStyle(color: CupertinoColors.black, fontSize: 12),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                    text: 'github.com/clockdiv/Face2OSC',
                    style: TextStyle(color: CupertinoColors.black, fontSize: 12, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        Uri url = Uri.https('github.com', '/clockdiv/Face2OSC');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          throw 'Could not launch $url';
                        }
                      }),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                    text: 'hfs-berlin.de',
                    style: TextStyle(color: CupertinoColors.black, fontSize: 12, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        Uri url = Uri.https('hfs-berlin.de');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          throw 'Could not launch $url';
                        }
                      }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String valueToString(double n) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
}

Future<String> getWifiIP() async {
  for (var interface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    developer.log('== Interface: ${interface.name} ==');
    for (var addr in interface.addresses) {
//      return '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}';

      developer.log('${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
    }
  }

  return 'Unknown';
}
