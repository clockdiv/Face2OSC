//import 'dart:html';
//import 'dart:js';
//import 'package:flutter/gestures.dart';
// import 'dart:ffi';

import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FaceOSC'),
        ),
        body: startScreen(),
      ),
    );
  }
}

Widget startScreen() {
  return ChangeNotifierProvider(
    create: (context) => FaceTrackingState(),
    child: const Column(
      children: [
        Expanded(
          flex: 6,
          child: HeadViewWidget(),
        ),
        Expanded(
          flex: 4,
          child: BlendShapesViewWidget(),
        ),
        Expanded(
          flex: 1,
          child: TempButton(),
        ),
      ],
    ),
  );
}

String valueToString(var n) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
}

// ========================
// === STATE ===
// ========================
class BlendShape {
  String name = "";
  double weight = 0.0;
  bool activated = true;
  BlendShape(this.name, this.weight, this.activated);
}

class FaceTrackingState extends ChangeNotifier {
  List<BlendShape> blendShapes = List.empty(growable: true);

  FaceTrackingState() {
    blendShapes.add(BlendShape("blendshape_A", 0.1, true));
    blendShapes.add(BlendShape("blendshape_B", 0.2, true));
    blendShapes.add(BlendShape("blendshape_C", 0.3, true));
  }

  var itemCount = 0;

  void updateBlendShape(BlendShape bs) {
    blendShapes[0] = bs;
    notifyListeners();
  }

  void updateItemCount(var count) {
    itemCount = count;
    notifyListeners();
  }
}

// ===========================
// === AR-HEAD VIEW WIDGET ===
// ===========================
class HeadViewWidget extends StatefulWidget {
  const HeadViewWidget({super.key});

  @override
  State<HeadViewWidget> createState() => _HeadViewWidgetState();
}

class _HeadViewWidgetState extends State<HeadViewWidget> {
  late ARKitController arkitController;
  late FaceTrackingState faceTrackingState;

  ARKitNode? node;

  ARKitNode? leftEye;
  ARKitNode? rightEye;

  

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    faceTrackingState = context.watch<FaceTrackingState>();

    // return Column(
    //   children: [
    //     ARKitSceneView(
    //       configuration: ARKitConfiguration.faceTracking,
    //       onARKitViewCreated: onARKitViewCreated,
    //     ),
    //     const BlendShapesViewWidget(),
    //   ],
    // );
    return ARKitSceneView(
      configuration: ARKitConfiguration.faceTracking,
      onARKitViewCreated: onARKitViewCreated,
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

    leftEye = _createEye(anchor.leftEyeTransform);
    arkitController.add(leftEye!, parentNodeName: anchor.nodeName);

    rightEye = _createEye(anchor.rightEyeTransform);
    arkitController.add(rightEye!, parentNodeName: anchor.nodeName);
  }

  ARKitNode _createEye(Matrix4 transform) {
    final position = Vector3(
      transform.getColumn(3).x,
      transform.getColumn(3).y,
      transform.getColumn(3).z,
    );
    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(Colors.yellow),
    );
    final sphere = ARKitBox(
        materials: [material], width: 0.03, height: 0.03, length: 0.03);

    return ARKitNode(geometry: sphere, position: position);
  }

  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitFaceAnchor && mounted) {
      final faceAnchor = anchor;

      arkitController.updateFaceGeometry(node!, faceAnchor.identifier);

      _updateEye(leftEye!, faceAnchor.leftEyeTransform,
          faceAnchor.blendShapes['eyeBlink_L'] ?? 0);

      _updateEye(rightEye!, faceAnchor.rightEyeTransform,
          faceAnchor.blendShapes['eyeBlink_R'] ?? 0);

      faceTrackingState.updateBlendShape(
          BlendShape('jawOpen', faceAnchor.blendShapes['jawOpen'] ?? 0, true));

      faceTrackingState.updateItemCount(faceAnchor.blendShapes.length);
    }
  }

  void _updateEye(ARKitNode node, Matrix4 transform, double blink) {
    final scale = Vector3(1, 1 - blink, 1);
    node.scale = scale;
  }
}

// ========================
// === DATA VIEW WIDGET ===
// ========================
class BlendShapesViewWidget extends StatelessWidget {
  const BlendShapesViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var faceTrackingState = context.watch<FaceTrackingState>();

    return ListView(
      shrinkWrap: true,
      children: [
        for (var s in faceTrackingState.blendShapes)
          BlendShapeWidget(s.name, s.weight, s.activated),
        // ListTile(
        //   title:
        //       Text("${s.name}  ${valueToString(s.weight)}  ${s.activated}"),
        //   onTap: () {
        //     faceTrackingState.updateBlendShape(BlendShape("Möp", 0.8, true));
        //   },
        // )
      ],
    );
  }
}

class BlendShapeWidget extends StatelessWidget {
  String name;
  double weight;
  bool activated;
  BlendShapeWidget(this.name, this.weight, this.activated, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name),
        Text(valueToString(weight)),
        //Text(activated.toString()),
      ],
    );
  }
}

// class BlendShapeWidget extends StatefulWidget {
//   const BlendShapeWidget({super.key});

//   @override
//   State<BlendShapeWidget> createState() => _BlendShapeWidgetState();
// }

// class _BlendShapeWidgetState extends State<BlendShapeWidget> {
//   late String name;
//   late double weight;
//   late bool activated;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Text(name),
//         Text(valueToString(weight)),
//         Text(activated.toString()),
//       ],
//     );
//   }
// }

// ========================
// === TEMP BUTTON ===
// ========================
class TempButton extends StatelessWidget {
  const TempButton({super.key});

  @override
  Widget build(BuildContext context) {
    var faceTrackingState = context.watch<FaceTrackingState>();
    return Row(
      children: [
        TextButton(
          child: const Text('press me'),
          onPressed: () {
            faceTrackingState.updateBlendShape(BlendShape("Möööp", 0.9, true));
          },
        ),
        Text(faceTrackingState.itemCount.toStringAsFixed(2)),
      ],
    );
  }
}
