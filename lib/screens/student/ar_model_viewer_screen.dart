import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

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
  void _showUsageTips() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'How to Explore',
                style: TextStyle(
                  fontSize: AppConstants.fontXL,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppConstants.paddingM),
              Text('Drag to rotate the model and pinch to zoom in or out.'),
              SizedBox(height: AppConstants.paddingS),
              Text(
                  'Use the built-in AR button on supported devices to place the model on a surface.'),
              SizedBox(height: AppConstants.paddingS),
              Text(
                  'Walk around the placed model to study structure, scale, and details from multiple angles.'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.studentPrimary,
        actions: [
          IconButton(
            onPressed: _showUsageTips,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Usage tips',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF4F8FF),
                    Color(0xFFE6EEF8),
                  ],
                ),
              ),
              child: ModelViewer(
                src: widget.modelAssetPath,
                alt: widget.alt,
                ar: true,
                arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                arPlacement: ArPlacement.floor,
                arScale: ArScale.auto,
                autoPlay: widget.autoLaunchAr,
                autoRotate: true,
                autoRotateDelay: widget.autoLaunchAr ? 0 : 1200,
                cameraControls: true,
                cameraOrbit: '0deg 75deg auto',
                minCameraOrbit: 'auto auto 55%',
                maxCameraOrbit: 'auto auto 220%',
                shadowIntensity: 1,
                exposure: 1.0,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingL),
            color: AppColors.surfaceLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  widget.autoLaunchAr
                      ? 'AR-ready preview is active. Use the viewer controls or launch on a supported device.'
                      : 'Interactive 3D preview is active. AR can still be launched on supported devices from the viewer.',
                  style: const TextStyle(
                    fontSize: AppConstants.fontM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
