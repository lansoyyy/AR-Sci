import 'dart:async';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';

class ARModelViewerScreen extends StatefulWidget {
  final String title;
  final String modelAssetPath;
  final String alt;
  final bool autoLaunchAr;

  const ARModelViewerScreen({
    super.key,
    required this.title,
    required this.modelAssetPath,
    required this.alt,
    this.autoLaunchAr = true,
  });

  @override
  State<ARModelViewerScreen> createState() => _ARModelViewerScreenState();
}

class _ARModelViewerScreenState extends State<ARModelViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: Stack(
        children: [
          ModelViewer(
            src: widget.modelAssetPath,
            alt: widget.alt,
            ar: true,
            autoRotate: true,
            cameraControls: true,
            backgroundColor: const Color.fromARGB(0xFF, 0x00, 0x00, 0x00),
            onWebViewCreated: (controller) {},
          ),
        ],
      ),
    );
  }
}
