//import 'dart:ffi';
//import 'dart:html';

//import 'dart:js';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:face2osc/screen_about.dart';
import 'package:face2osc/screen_settings.dart';
import 'package:flutter/material.dart';
//import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face2OSC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FaceDetectionPage(),
    );
  }
}

class FaceDetectionPage extends StatefulWidget {
  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class trackingFeature {
  double weight = 0.0;
  bool enabled = true;

  trackingFeature() {
    weight = 0.1;
    enabled = true;
  }
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  late ARKitController arkitController;
  ARKitNode? node;

  ARKitNode? leftEye;
  ARKitNode? rightEye;

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

  _FaceDetectionPageState() {
    features.forEach((element) {
      featuresSettings[element] = new trackingFeature();
    });
    featuresSettings["browDown_R"]!.enabled = false;
  }

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          //appBar: AppBar(title: const Text('Face Detection Sample')),
          body: Column(
        children: [
          // ----------- 4. Stacked ARKitSceneView with PAGEVIEW. Pageview has an empty Container and the SettingsScreen
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ARKitSceneView(
                  configuration: ARKitConfiguration.faceTracking,
                  onARKitViewCreated: onARKitViewCreated,
                ),
                PageView(
                  controller: PageController(initialPage: 1),
                  physics: const ClampingScrollPhysics(),
                  children: [
                    ScreenAbout(),
                    Container(),
                    ScreenSettings(),
                  ],
                ),
              ],
            ),
          ),

          // ----------- Test 3. Standard ARKitSceneView with STACKED Settings from Right
          // Expanded(
          //   flex: 3,
          //   child: Stack(
          //     children: [
          //       ARKitSceneView(
          //         configuration: ARKitConfiguration.faceTracking,
          //         onARKitViewCreated: onARKitViewCreated,
          //       ),
          //       SettingsScreen()
          //     ],
          //   ),
          // ),

          // ----------- Test 2. Standard ARKitSceneView with PAGEVIEW swipe Settings from Right
          // Expanded(
          //   flex: 3,
          //   child: PageView(
          //     children: [
          //       ARKitSceneView(
          //         configuration: ARKitConfiguration.faceTracking,
          //         onARKitViewCreated: onARKitViewCreated,
          //       ),
          //       SettingsScreen(),
          //     ],
          //   ),
          // ),
          // ----------- Test 1. Standard ARKitSceneView
          // Expanded(
          //   flex: 3,
          //   child: Container(
          //     child: ARKitSceneView(
          //       configuration: ARKitConfiguration.faceTracking,
          //       onARKitViewCreated: onARKitViewCreated,
          //     ),
          //   ),
          // ),
          // ----------- FeaturesSettings (BlendshapeWidgetList) View
          Expanded(
            flex: 2,
            child: getBlendshapeWidgetList(featuresSettings),
          ),
        ],
      ));

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

    // leftEye = _createEye(anchor.leftEyeTransform);
    // arkitController.add(leftEye!, parentNodeName: anchor.nodeName);
    // rightEye = _createEye(anchor.rightEyeTransform);
    // arkitController.add(rightEye!, parentNodeName: anchor.nodeName);
  }

  // ARKitNode _createEye(Matrix4 transform) {
  //   final position = vector.Vector3(
  //     transform.getColumn(3).x,
  //     transform.getColumn(3).y,
  //     transform.getColumn(3).z,
  //   );
  //   final material = ARKitMaterial(
  //     diffuse: ARKitMaterialProperty.color(Colors.yellow),
  //   );
  //   final sphere = ARKitBox(
  //       materials: [material], width: 0.03, height: 0.03, length: 0.03);

  //   return ARKitNode(geometry: sphere, position: position);
  // }

  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitFaceAnchor && mounted) {
      final faceAnchor = anchor;
      arkitController.updateFaceGeometry(node!, anchor.identifier);

      // _updateEye(leftEye!, faceAnchor.leftEyeTransform,
      //     faceAnchor.blendShapes['eyeBlink_L'] ?? 0);
      // _updateEye(rightEye!, faceAnchor.rightEyeTransform,
      //     faceAnchor.blendShapes['eyeBlink_R'] ?? 0);

      setState(() {
        featuresSettings.forEach((key, value) {
          featuresSettings[key]!.weight = anchor.blendShapes[key] ?? 0;
        });
      });
    }
  }

  // void _updateEye(ARKitNode node, Matrix4 transform, double blink) {
  //   final scale = vector.Vector3(1, 1 - blink, 1);
  //   node.scale = scale;
  // }

  Widget getBlendshapeWidgetList(
      Map<String, trackingFeature> featuresSettings) {
    return ListView(
      children: [
        for (int i = 0; i < featuresSettings.length; i++)
          Slidable(
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.18,
              children: [
                SlidableAction(
                  onPressed: (BuildContext context) {
                    setState(() {
                      featuresSettings.values.elementAt(i).enabled =
                          !featuresSettings.values.elementAt(i).enabled;
                      // developer.log("pressed " + i.toString() + " and toggled it " + featuresSettings.values.elementAt(i).enabled.toString());
                    });
                  },
                  icon: featuresSettings.values.elementAt(i).enabled
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            child: blendshapeWidget(
                featuresSettings.keys.elementAt(i),
                featuresSettings.values.elementAt(i).weight,
                featuresSettings.values.elementAt(i).enabled,
                i),
          )
      ],
    );
  }

  Widget blendshapeWidget(String name, double weight, bool enabled, int index) {
    Color bgColor = (index % 2 == 0) ? Colors.white : Colors.grey.shade50;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        // color: bgColor,
        border: Border(top: BorderSide(width: 1, color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(valueToString(weight)),
            ),
            Expanded(
              flex: 2,
              child: Container(
                  height: 60,
                  //color: Colors.grey.shade500,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: weight * 100,
                      height: 20,
                      child: Container(color: Colors.grey.shade500),
                    ),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: enabled ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

//void toggleBlendshapeFeature(BuildContext context) {}
}

String valueToString(double n) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
}

/* the getBlendshapeWidgetList version without the Slidable
Widget getBlendshapeWidgetList(Map featureElements) {
  return ListView(
    children: [
      for (int i = 0; i < featureElements.length; i++)
        blendshapeWidget(featureElements.keys.elementAt(i),
            featureElements.values.elementAt(i), i)
    ],
  );
}
*/

