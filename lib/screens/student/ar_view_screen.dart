import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class ARViewScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const ARViewScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  String _selectedARMode = 'simulation';
  bool _isPlaying = false;
  bool _labelsVisible = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        backgroundColor: AppColors.studentPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showARInstructions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // AR View Area (Placeholder)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    AppColors.studentPrimary.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  // AR Placeholder Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getARIcon(),
                          size: 120,
                          color: AppColors.textWhite.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.paddingL),
                        Text(
                          _getARModeTitle(),
                          style: const TextStyle(
                            fontSize: AppConstants.fontXXL,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          'AR View Placeholder',
                          style: TextStyle(
                            fontSize: AppConstants.fontL,
                            color: AppColors.textWhite.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        Text(
                          'Camera and 3D rendering will be implemented here',
                          style: TextStyle(
                            fontSize: AppConstants.fontM,
                            color: AppColors.textWhite.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // AR Controls Overlay (Top)
                  Positioned(
                    top: AppConstants.paddingM,
                    left: AppConstants.paddingM,
                    right: AppConstants.paddingM,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Language Switch
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingM,
                            vertical: AppConstants.paddingS,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: Colors.black87,
                            underline: const SizedBox(),
                            style: const TextStyle(color: AppColors.textWhite),
                            items: const [
                              DropdownMenuItem(value: 'English', child: Text('English')),
                              DropdownMenuItem(value: 'Filipino', child: Text('Filipino')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedLanguage = value!);
                            },
                          ),
                        ),
                        
                        // Toggle Labels
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _labelsVisible ? Icons.label : Icons.label_off,
                              color: AppColors.textWhite,
                            ),
                            onPressed: () {
                              setState(() => _labelsVisible = !_labelsVisible);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Interactive Labels Placeholder (if visible)
                  if (_labelsVisible && _selectedARMode == 'labels')
                    Positioned(
                      top: 150,
                      left: 50,
                      child: _ARLabel(
                        title: 'Lungs',
                        description: 'Organs for breathing',
                      ),
                    ),
                  if (_labelsVisible && _selectedARMode == 'labels')
                    Positioned(
                      bottom: 200,
                      right: 60,
                      child: _ARLabel(
                        title: 'Heart',
                        description: 'Pumps blood throughout body',
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Control Panel
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusXL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AR Mode Selector
                const Text(
                  'AR Mode',
                  style: TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ARModeChip(
                        icon: Icons.play_circle_outline,
                        label: 'Simulation',
                        isSelected: _selectedARMode == 'simulation',
                        onTap: () {
                          setState(() => _selectedARMode = 'simulation');
                        },
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      _ARModeChip(
                        icon: Icons.label_outline,
                        label: 'Labels',
                        isSelected: _selectedARMode == 'labels',
                        onTap: () {
                          setState(() => _selectedARMode = 'labels');
                        },
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      _ARModeChip(
                        icon: Icons.science_outlined,
                        label: 'Periodic Table',
                        isSelected: _selectedARMode == 'periodic',
                        onTap: () {
                          setState(() => _selectedARMode = 'periodic');
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingL),
                
                // Playback Controls (for Simulation mode)
                if (_selectedARMode == 'simulation') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 32,
                        color: AppColors.studentPrimary,
                        onPressed: () {},
                      ),
                      const SizedBox(width: AppConstants.paddingL),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.studentPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.textWhite,
                          ),
                          iconSize: 40,
                          onPressed: () {
                            setState(() => _isPlaying = !_isPlaying);
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingL),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 32,
                        color: AppColors.studentPrimary,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  
                  // Speed Control
                  Row(
                    children: [
                      const Icon(Icons.speed, color: AppColors.textSecondary),
                      Expanded(
                        child: Slider(
                          value: 1.0,
                          min: 0.5,
                          max: 2.0,
                          divisions: 3,
                          label: '1x',
                          activeColor: AppColors.studentPrimary,
                          onChanged: (value) {},
                        ),
                      ),
                      const Text('Speed'),
                    ],
                  ),
                ],
                
                // Feature Description
                const SizedBox(height: AppConstants.paddingL),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.studentPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.studentPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.paddingS),
                          Text(
                            _getARModeTitle(),
                            style: const TextStyle(
                              fontSize: AppConstants.fontL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.studentPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Text(
                        _getARModeDescription(),
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
          ),
        ],
      ),
    );
  }

  IconData _getARIcon() {
    switch (_selectedARMode) {
      case 'simulation':
        return Icons.play_circle_outline;
      case 'labels':
        return Icons.label_outline;
      case 'periodic':
        return Icons.science_outlined;
      default:
        return Icons.view_in_ar;
    }
  }

  String _getARModeTitle() {
    switch (_selectedARMode) {
      case 'simulation':
        return 'Simulation & Animation';
      case 'labels':
        return 'Interactive Learning Labels';
      case 'periodic':
        return 'AR Periodic Table';
      default:
        return 'AR View';
    }
  }

  String _getARModeDescription() {
    switch (_selectedARMode) {
      case 'simulation':
        return 'Watch animated models of scientific systems like the digestive, circulatory, and respiratory systems. Play, pause, or slow down each phase for better comprehension.';
      case 'labels':
        return 'Tap on parts to learn their names, definitions, functions, and importance. Pop-up info cards provide detailed explanations.';
      case 'periodic':
        return 'Explore the periodic table in 3D AR format. Select elements to view their atomic structure, model, or sample appearance.';
      default:
        return '';
    }
  }

  void _showARInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Instructions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InstructionItem(
                icon: Icons.camera_alt,
                text: 'Point your camera at a flat surface',
              ),
              _InstructionItem(
                icon: Icons.touch_app,
                text: 'Tap to place 3D models',
              ),
              _InstructionItem(
                icon: Icons.pinch,
                text: 'Pinch to zoom in/out',
              ),
              _InstructionItem(
                icon: Icons.rotate_right,
                text: 'Drag to rotate models',
              ),
              _InstructionItem(
                icon: Icons.label,
                text: 'Tap labels for more information',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ARModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ARModeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.studentPrimary
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          border: Border.all(
            color: isSelected
                ? AppColors.studentPrimary
                : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.textWhite
                  : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontM,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.textWhite
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ARLabel extends StatelessWidget {
  final String title;
  final String description;

  const _ARLabel({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.studentPrimary,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.textWhite,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            description,
            style: const TextStyle(
              fontSize: AppConstants.fontS,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: Row(
        children: [
          Icon(icon, color: AppColors.studentPrimary),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: AppConstants.fontM),
            ),
          ),
        ],
      ),
    );
  }
}
