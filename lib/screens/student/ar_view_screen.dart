import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class ARViewScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final List<String> arItems;
  final String? color;

  const ARViewScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    this.arItems = const [],
    this.color,
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        backgroundColor: _getSubjectColor(widget.color),
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
                    _getARModeColor().withOpacity(0.3),
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
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusRound),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: Colors.black87,
                            underline: const SizedBox(),
                            style: const TextStyle(color: AppColors.textWhite),
                            items: const [
                              DropdownMenuItem(
                                  value: 'English', child: Text('English')),
                              DropdownMenuItem(
                                  value: 'Filipino', child: Text('Filipino')),
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
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusRound),
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
                        color: AppColors.biology,
                      ),
                    ),
                  if (_labelsVisible && _selectedARMode == 'labels')
                    Positioned(
                      bottom: 200,
                      right: 60,
                      child: _ARLabel(
                        title: 'Heart',
                        description: 'Pumps blood throughout body',
                        color: AppColors.biology,
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
                        color: AppColors.simulation,
                        onTap: () {
                          setState(() => _selectedARMode = 'simulation');
                        },
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      _ARModeChip(
                        icon: Icons.label_outline,
                        label: 'Labels',
                        isSelected: _selectedARMode == 'labels',
                        color: AppColors.biology,
                        onTap: () {
                          setState(() => _selectedARMode = 'labels');
                        },
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      _ARModeChip(
                        icon: Icons.science_outlined,
                        label: '3D Explorer',
                        isSelected: _selectedARMode == 'periodic',
                        color: AppColors.periodicTable,
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
                        color: _getARModeColor(),
                        onPressed: () {},
                      ),
                      const SizedBox(width: AppConstants.paddingL),
                      Container(
                        decoration: BoxDecoration(
                          color: _getARModeColor(),
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
                        color: _getARModeColor(),
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
                          activeColor: _getARModeColor(),
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
                    color: _getARModeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _getARModeColor(),
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.paddingS),
                          Text(
                            _getARModeTitle(),
                            style: TextStyle(
                              fontSize: AppConstants.fontL,
                              fontWeight: FontWeight.w600,
                              color: _getARModeColor(),
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

  Color _getARModeColor() {
    switch (_selectedARMode) {
      case 'simulation':
        return AppColors.simulation;
      case 'labels':
        return AppColors.biology;
      case 'periodic':
        return AppColors.periodicTable;
      default:
        return AppColors.arFeature;
    }
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
        return '3D Explorer';
      default:
        return 'AR View';
    }
  }

  String _getARModeDescription() {
    final lessonId = widget.lessonId;
    switch (_selectedARMode) {
      case 'simulation':
        if (lessonId == 'g9_volcanoes') {
          return 'Experience volcanic eruptions in AR. See magma movement, ash clouds, and lava flows in real-time simulations.';
        } else if (lessonId == 'g9_earthquakes') {
          return 'See how tectonic plates move and generate seismic waves. Visualize epicenters, focus points, and ground shaking in 3D.';
        } else if (lessonId == 'g9_climate') {
          return 'Observe how sunlight, atmosphere, and oceans interact to create different climates and weather patterns.';
        } else if (lessonId == 'g9_constellations') {
          return 'Watch constellations form in the night sky and see how Earth’s motion changes what we observe over time.';
        } else if (lessonId == 'g9_energy') {
          return 'Explore how energy is transformed between kinetic, potential, thermal, and electrical forms using interactive simulations.';
        } else if (lessonId == 'g9_forces') {
          return 'Visualize pushes, pulls, friction, and gravity acting on objects to see how forces change motion.';
        } else if (lessonId == 'g9_motion') {
          return 'Track objects in motion with distance–time and velocity–time animations that respond as you change variables.';
        } else if (lessonId == 'g9_electricity') {
          return 'Simulate current flow in simple circuits and see how bulbs, resistors, and switches respond in real time.';
        } else if (lessonId == 'g9_waves') {
          return 'Observe mechanical and electromagnetic waves as they reflect, refract, and interfere with each other.';
        }
        return 'Watch animated models that bring this lesson to life. Play, pause, or slow down each phase for better understanding.';
      case 'labels':
        if (lessonId == 'g9_volcanoes') {
          return 'Tap on volcano parts to learn about magma chambers, vents, and eruption types. Labels explain each structure.';
        } else if (lessonId == 'g9_earthquakes') {
          return 'Tap on faults, plates, and instruments like seismographs to see what role they play during an earthquake.';
        } else if (lessonId == 'g9_climate') {
          return 'Tap on climate graphs, symbols, and regions to learn what they represent and how they are interpreted.';
        } else if (lessonId == 'g9_constellations') {
          return 'Tap on stars and constellation lines to reveal names, stories, and how they are used for navigation.';
        } else if (lessonId == 'g9_energy') {
          return 'Tap on objects to see which type of energy they show and how energy is being transformed.';
        } else if (lessonId == 'g9_forces') {
          return 'Tap on force arrows and contact points to learn about magnitude, direction, and type of force.';
        } else if (lessonId == 'g9_motion') {
          return 'Tap on graphs and moving objects to see what changing speed or direction does to the motion.';
        } else if (lessonId == 'g9_electricity') {
          return 'Tap on circuit components to learn their symbols, functions, and how they affect current, voltage, and resistance.';
        } else if (lessonId == 'g9_waves') {
          return 'Tap on crests, troughs, and ray diagrams to see how wavelength, frequency, and amplitude are related.';
        }
        return 'Tap on parts of the AR scene to reveal names, descriptions, and key facts for this lesson.';
      case 'periodic':
        return 'Explore detailed 3D models related to this topic, such as volcano interiors, tectonic plates, the night sky, circuits, or wave patterns.';
      default:
        return '';
    }
  }

  void _showARInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.lessonTitle} Instructions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InstructionItem(
                icon: Icons.camera_alt,
                text: 'Point your camera at a flat surface',
                color: _getARModeColor(),
              ),
              _InstructionItem(
                icon: Icons.touch_app,
                text: 'Tap to place 3D models',
                color: _getARModeColor(),
              ),
              _InstructionItem(
                icon: Icons.pinch,
                text: 'Pinch to zoom in/out',
                color: _getARModeColor(),
              ),
              _InstructionItem(
                icon: Icons.rotate_right,
                text: 'Drag to rotate models',
                color: _getARModeColor(),
              ),
              _InstructionItem(
                icon: Icons.label,
                text: 'Tap labels for more information',
                color: _getARModeColor(),
              ),
              if (widget.arItems.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingM),
                const Text(
                  'Available AR Items:',
                  style: TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                ...widget.arItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 16,
                            color: _getARModeColor(),
                          ),
                          const SizedBox(width: AppConstants.paddingS),
                          Expanded(
                            child: Text(
                              item,
                              style:
                                  const TextStyle(fontSize: AppConstants.fontM),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
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

  Color _getSubjectColor(String? colorName) {
    switch (colorName) {
      case 'physics':
        return AppColors.physics;
      case 'chemistry':
        return AppColors.chemistry;
      case 'biology':
        return AppColors.biology;
      case 'earthScience':
        return AppColors.primary;
      default:
        return AppColors.studentPrimary;
    }
  }
}

class _ARModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ARModeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
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
          color: isSelected ? color : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontM,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
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
  final Color color;

  const _ARLabel({
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: color,
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
  final Color color;

  const _InstructionItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: Row(
        children: [
          Icon(icon, color: color),
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
