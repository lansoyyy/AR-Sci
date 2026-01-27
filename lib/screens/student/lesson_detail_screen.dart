import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get lesson arguments passed from navigation
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? lessonData;

    if (args is Map<String, dynamic>) {
      lessonData = args;
    } else if (args is String) {
      // Find lesson by ID if only ID was passed
      lessonData = AppConstants.allLessons.firstWhere(
        (lesson) => lesson['id'] == args,
        orElse: () => AppConstants.allLessons.first,
      );
    } else {
      // Default to first lesson
      lessonData = AppConstants.allLessons.first;
    }

    final lesson = lessonData ?? AppConstants.allLessons.first;
    final Color subjectColor = _getSubjectColor(lesson['color']);
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson['title']),
        backgroundColor: subjectColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Video Placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    subjectColor,
                    subjectColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: AppColors.textWhite,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: subjectColor,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: Text(
                          lesson['subject'],
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: AppConstants.fontS,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: Text(
                          lesson['grade'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppConstants.fontS,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Title
                  Text(
                    lesson['title'],
                    style: const TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingM),

                  // Description
                  Text(
                    lesson['description'],
                    style: const TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  if (lesson['id'] == 'g9_volcanoes') ...[
                    const SizedBox(height: AppConstants.paddingXL),
                    const Text(
                      'AR Topics',
                      style: TextStyle(
                        fontSize: AppConstants.fontXL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _VolcanoTopics(subjectColor: subjectColor),
                  ],

                  const SizedBox(height: AppConstants.paddingXL),

                  // Progress
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusRound),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    '65% Complete',
                    style: const TextStyle(
                      fontSize: AppConstants.fontM,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Content Sections
                  const Text(
                    'Lesson Content',
                    style: TextStyle(
                      fontSize: AppConstants.fontXL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),

                  // Dynamic content sections based on lesson
                  ..._getContentSections(lesson)
                      .map((section) => _ContentSection(
                            title: section['title'],
                            duration: section['duration'],
                            isCompleted: section['isCompleted'],
                            isActive: section['isActive'],
                            onTap: () {},
                            subjectColor: subjectColor,
                          )),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Download Materials
                  Card(
                    child: ListTile(
                      leading:
                          Icon(Icons.download_outlined, color: subjectColor),
                      title: const Text('Download Study Materials'),
                      subtitle: const Text('PDF • 2.5 MB'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // AR View Button
                  CustomButton(
                    text: 'View in AR',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/ar-view',
                        arguments: lesson,
                      );
                    },
                    fullWidth: true,
                    backgroundColor: subjectColor,
                    icon: Icons.view_in_ar,
                  ),

                  const SizedBox(height: AppConstants.paddingM),

                  // Continue Button
                  CustomButton(
                    text: 'Continue Learning',
                    onPressed: () {},
                    fullWidth: true,
                    type: ButtonType.outlined,
                    textColor: subjectColor,
                    icon: Icons.play_arrow,
                  ),

                  const SizedBox(height: AppConstants.paddingL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolcanoTopics extends StatelessWidget {
  final Color subjectColor;

  const _VolcanoTopics({required this.subjectColor});

  @override
  Widget build(BuildContext context) {
    final topic1Items = <Map<String, String>>[
      {
        'title': 'Cone',
        'body':
            'the most striking part of the volcano, usually composed of mixtures of lava and pyroclastic. Viscous and slow-moving granitic magma forms high-sided steep cones; while fast-moving basaltic magma creates low to almost flat cones.',
      },
      {
        'title': 'Vent',
        'body':
            'the opening through which an eruption takes place. This main part of a volcano supplies the magma from the underlying source to the top of the volcano. They can be straight or convoluted.',
      },
      {
        'title': 'Magma chamber',
        'body':
            'the large underground pool of liquid rock found beneath the earth\'s crust.',
      },
      {
        'title': 'Crater',
        'body':
            'a basin-like depression over a vent at the summit of the cone.',
      },
      {
        'title': 'Caldera',
        'body': 'a volcanic depression much larger than the original crater.',
      },
      {
        'title': 'Lava',
        'body':
            'the rock or magma expelled from a volcano during eruption. Its temperature upon ejection can reach up to 700°C, hence it flows until it cools and hardens.',
      },
      {
        'title': 'Dikes',
        'body':
            'the barrier or obstacles in a volcano. Dikes are found in igneous forms which, under great pressure, cut fractures or fissures across previously formed metamorphic, sedimentary, or igneous rocks.',
      },
      {
        'title': 'Sills',
        'body':
            'otherwise known as intrusive sheets; they are solidified lava flows that originally forced their way between and parallel to older layers of rocks.',
      },
      {
        'title': 'Conduits',
        'body': 'channel or pipe conveying liquid materials such as magma.',
      },
      {
        'title': 'Flank',
        'body': 'the side of a volcano.',
      },
      {
        'title': 'Summit',
        'body': 'the highest point or apex of a volcano.',
      },
      {
        'title': 'Throat',
        'body': 'the entrance of a volcano.',
      },
      {
        'title': 'Ash cloud',
        'body':
            'expelled in the atmosphere; volcanic ash or ash cloud is composed of pulverized rock and glass created during eruption.',
      },
      {
        'title': 'Volcanic bombs',
        'body':
            'the chunks of lava blasted into the air which solidify before reaching the ground. Their sizes may vary and can measure up to 64 mm in diameter.',
      },
      {
        'title': 'Pyroclastic flow',
        'body':
            'fast-moving currents of hot gases and rock travelling downhill from a volcano. The gases can reach temperatures of more than 1000°C and can move up to a speed of 700 km/hr. This includes pumice flow, ash flow, block and ash flow, glowing and erupting clouds called nuée ardente, and avalanche. In terms of size, particles with less than 2 mm diameter are called ashes; those with 2-64 mm in diameter are called lapilli; while those bigger than 64 mm in diameter are called blocks and bombs.',
      },
      {
        'title': 'Tephra fall',
        'body':
            'refers to fragmented material that consists of pumice, scoria, lithic materials, or crystals or combination of the four.',
      },
      {
        'title': 'Lahar',
        'body':
            'also called mudflows: they are flowing mixture of volcanic debris and water. They are classified as primary or hot when associated with volcanic eruption, or as cold lahar when they are caused by heavy rainfall.',
      },
    ];

    final topic2Items = <Map<String, String>>[
      {
        'title': 'Introduction to Volcanoes',
        'body':
            'Volcanoes are powerful natural formations that reveal how dynamic the Earth’s surface can be. One of the most remarkable examples is Parícutin Volcano in Mexico, which allowed scientists to observe the complete birth and development of a volcano for the first time. Emerging in 1943 as a small crack in the Earth’s crust, Parícutin quickly evolved through explosions, steam emissions, and violent eruptions that released pyroclastic materials in all directions. This rare event provided geologists with valuable insights into volcanic activity, growth, and behavior, making Parícutin an important case study in understanding how volcanoes form and develop over time.',
      },
      {
        'title': 'Cinder Cones',
        'body':
            'Cinder cones, the most basic type of volcano, are steep, conical hills formed by the violent ejection and solidification of gas-charged basaltic lava. These relatively small volcanoes, typically less than 250 meters high and 500 meters wide, are considered a temporary landform on geological timescales. Cinder cones are commonly found on the flanks or within the calderas of larger shield volcanoes, particularly in regions like western North America, providing insights into the dynamic volcanic processes shaping the Earth\'s surface.',
      },
      {
        'title': 'Composite Volcanoes',
        'body':
            'Composite volcanoes, or stratovolcanoes, are complex volcanic structures characterized by alternating layers of pyroclastic materials and solidified lava flows. These towering landforms can reach heights exceeding 6,000 meters and are primarily composed of andesite, tephra, and other volcanic materials. During eruptions, the viscous lava flows can travel great distances, and the symmetrical slopes exhibit an intermediate steepness. Iconic examples of composite volcanoes include Mount Fuji, Mount Cotopaxi, and Mount Rainier, showcasing the remarkable complexity and power of volcanic processes that shape the Earth\'s surface.',
      },
      {
        'title': 'Shield Volcanoes',
        'body':
            'Shield volcanoes are characterized by their broad, gently sloping profiles, built up by many layers of low-viscosity lava flows. The slopes of these volcanoes typically range from 2 to 10 degrees from the horizontal, creating a flattened, dome-like shape. This gentle slope is due to the fluidity of the basaltic lava, which allows it to spread out rather than build up steep, explosive structures. Notable examples include the massive Mauna Loa in Hawaii, which stands over 28,000 feet from the ocean floor. Shield volcanoes provide insights into the diverse volcanic processes that have shaped the Earth\'s surface.',
      },
      {
        'title': 'Volcanic Domes',
        'body':
            'Volcanic domes, or lava domes, are rounded, steep-sided mounds formed by the accumulation of viscous lava, primarily dacite or rhyolite. The thick lava piles up and solidifies around the vent, creating the dome-like structure. These domes typically form within or on the flanks of larger composite volcanoes. While associated with non-explosive eruptions, the lava mass can sometimes collapse, resulting in hazardous avalanches. Volcanic domes offer insights into the diverse volcanic processes shaping the Earth\'s surface.',
      },
      {
        'title': 'Supervolcanoes',
        'body':
            'Supervolcanoes are defined as volcanic centers that have recorded eruptions with a magnitude of 8 or higher on the Volcanic Explosivity Index (VEI). This means they can eject over 1,000 cubic kilometers of magma and materials, making them the most catastrophic volcanic events on Earth. The VEI scale, created by geologists, is used to measure the size and power of these eruptions. Understanding supervolcanoes is crucial for assessing and mitigating the global risks they pose.',
      },
      {
        'title': 'Submarine volcanoes',
        'body':
            'Submarine volcanoes erupt underwater, mainly near ocean ridges, producing pillow lava in rounded shapes. They are smaller than terrestrial volcanoes due to high pressure, with limited gas release that rarely disturbs the surface. Interactions between lava and seawater can create black sand beaches. Hydrothermal vents near these volcanoes support deep-sea ecosystems by providing energy and nutrients. Understanding them is key to studying oceanic geology and ecosystems.',
      },
      {
        'title': 'Subglacial Volcanoes',
        'body':
            'Subglacial volcanoes, also called glaciovolcanoes, form when eruptions occur beneath glaciers or ice sheets. The rising lava melts the overlying ice, creating a lake resembling the pillow lava of submarine volcanoes. Subglacial eruptions can trigger jökulhlaups, or massive floods of water, as seen with Iceland\'s Katla Volcano. One of Iceland\'s subglacial volcanoes is among the largest, with a peak discharge rivaling the combined flow of major rivers. Understanding these unique volcanic systems is important for studying geological processes and hazards in glaciated regions.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOPIC I. Features of a Volcano',
          style: TextStyle(
            fontSize: AppConstants.fontL,
            fontWeight: FontWeight.w700,
            color: subjectColor,
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        ...List.generate(topic1Items.length, (index) {
          final item = topic1Items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${item['title']}',
                      style: const TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      item['body'] ?? '',
                      style: const TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: AppConstants.paddingL),
        Text(
          'TOPIC II. Types of Volcanoes',
          style: TextStyle(
            fontSize: AppConstants.fontL,
            fontWeight: FontWeight.w700,
            color: subjectColor,
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        ...List.generate(topic2Items.length, (index) {
          final item = topic2Items[index];
          final headingPrefix = index == 0 ? '' : '${index}. ';
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.paddingL),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$headingPrefix${item['title']}',
                      style: const TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      item['body'] ?? '',
                      style: const TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _ImagePlaceholder(color: subjectColor),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color color;

  const _ImagePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: color, size: 36),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'Image Placeholder',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingXS),
            const Text(
              'Attach an image here later',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppConstants.fontS,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final String title;
  final String duration;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;
  final Color subjectColor;

  const _ContentSection({
    required this.title,
    required this.duration,
    this.isCompleted = false,
    this.isActive = false,
    required this.onTap,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      color: isActive ? subjectColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : isActive
                    ? AppColors.studentPrimary
                    : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.play_arrow,
            color: isCompleted || isActive
                ? AppColors.textWhite
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(duration),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
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

List<Map<String, dynamic>> _getContentSections(Map<String, dynamic> lesson) {
  switch (lesson['id']) {
    case 'g9_volcanoes':
      return [
        {
          'title': 'Introduction to Volcanoes',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Types of Volcanoes',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Causes of Eruptions',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Volcanic Hazards & Risks',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Volcano Exploration',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_earthquakes':
      return [
        {
          'title': 'Earth’s Plates and Faults',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'How Earthquakes Happen',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Seismic Waves',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Measuring Earthquakes',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Preparedness and Safety',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_climate':
      return [
        {
          'title': 'Weather vs Climate',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Factors Affecting Climate',
          'duration': '12 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Climate Zones',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Climate Change Impacts',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Climate Visualizations',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_constellations':
      return [
        {
          'title': 'Patterns in the Night Sky',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Major Constellations',
          'duration': '12 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Seasonal Sky Changes',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Constellations and Navigation',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Star Map Exploration',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_energy':
      return [
        {
          'title': 'Forms of Energy',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Work and Power',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Energy Transformations',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Conservation of Energy',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Energy in Everyday Life',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_forces':
      return [
        {
          'title': 'Introduction to Forces',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Types of Forces',
          'duration': '12 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Net Force and Equilibrium',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Friction and Air Resistance',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Force Simulations',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_motion':
      return [
        {
          'title': 'Describing Motion',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Speed and Velocity',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Acceleration',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Graphs of Motion',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Motion in Real Life',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_electricity':
      return [
        {
          'title': 'Basic Electric Quantities',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Simple Circuits',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Series and Parallel Circuits',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Safety with Electricity',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Circuit Builder',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_waves':
      return [
        {
          'title': 'What Are Waves?',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Wave Properties',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Sound Waves',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Light Waves',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Wave Applications',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    default:
      return [
        {
          'title': 'Introduction',
          'duration': '5 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Main Content',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Practice',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
  }
}
