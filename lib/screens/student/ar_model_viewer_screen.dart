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
  WebViewController? _controller;
  Timer? _autoLaunchTimer;
  bool _hasAttemptedAutoLaunch = false;

  @override
  void dispose() {
    _autoLaunchTimer?.cancel();
    super.dispose();
  }

  Future<void> _activateAr() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await controller.runJavaScript(
        """
        (function() {
          const mv = document.querySelector('model-viewer');
          if (mv && typeof mv.activateAR === 'function') {
            mv.activateAR();
          }
        })();
        """,
      );
    } catch (_) {}
  }

  void _scheduleAutoLaunch() {
    if (!widget.autoLaunchAr) return;
    if (_hasAttemptedAutoLaunch) return;

    _hasAttemptedAutoLaunch = true;
    _autoLaunchTimer?.cancel();
    _autoLaunchTimer = Timer(const Duration(seconds: 2), () {
      _activateAr();
    });
  }

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
            onWebViewCreated: (controller) {
              _controller = controller;
              _scheduleAutoLaunch();
            },
          ),
          Positioned(
            left: AppConstants.paddingM,
            right: AppConstants.paddingM,
            bottom: AppConstants.paddingM,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _activateAr,
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text('View in AR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.studentPrimary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingM,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
