import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

import 'ar_model_viewer_screen.dart';

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

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ARViewScreenState extends State<ARViewScreen> {
  static final List<_ARModelItem> _volcanoModels = <_ARModelItem>[
    _ARModelItem(
      title: 'Structure of a Volcano',
      description:
          'This illustration shows a cross-sectional view of a volcano, highlighting its internal and external parts. '
          'At the top is the crater where lava, ash, and gases erupt. Inside the volcano is a magma chamber that stores '
          'molten rock beneath the Earth\'s surface. When pressure builds up, magma travels through the main vent and erupts '
          'as lava. The image also shows flowing lava on the sides of the volcano and layers of rock and ash formed from previous eruptions.',
      keyComponents: <String>[
        'Magma chamber',
        'Main vent',
        'Crater',
        'Lava flow',
        'Ash cloud',
        'Layers of rock and soil',
      ],
      type: 'Educational science illustration',
      mainFocus: 'Parts and structure of a volcano',
      purpose:
          'To help students understand how volcanoes work and identify their different parts',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance:
          'Explains volcanic eruptions, formation of landforms, and natural hazards related to volcanoes',
      modelAssetPath: 'assets/models/1.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic1.png',
    ),
    _ARModelItem(
      title: 'Volcanic Eruption Process',
      description:
          'This image illustrates the process of a volcanic eruption from beneath the Earth\'s surface. It shows magma rising '
          'from below through a central vent due to intense heat and pressure inside the Earth. As the magma reaches the surface, '
          'it erupts as lava, releasing ash, smoke, and gases into the air. The diagram also presents the layers of the Earth\'s crust '
          'surrounding the volcano and how molten rock moves upward during an eruption.',
      keyComponents: <String>[
        'Magma beneath the Earth\'s crust',
        'Central vent / conduit',
        'Lava flow',
        'Ash and gas cloud',
        'Earth\'s crust layers',
      ],
      type: 'Scientific diagram / Educational illustration',
      mainFocus: 'Process of a volcanic eruption',
      purpose:
          'To explain how volcanic eruptions occur and how magma reaches the surface',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 7–10',
      importance:
          'Helps learners understand volcanic activity, natural disasters, and magma movement',
      modelAssetPath: 'assets/models/2.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic2.png',
    ),
    _ARModelItem(
      title: 'Active Volcano Crater with Lava Flow',
      description:
          'This image shows a detailed view of an active volcano with a large central crater filled with glowing molten lava. '
          'The hot lava spreads from the center toward the sides of the volcano, forming bright orange streams along the rocky surface. '
          'The surrounding landscape is made up of hardened volcanic rocks and ash deposits from previous eruptions. The image highlights '
          'the intense heat and activity within the crater, demonstrating how lava flows during an eruption.',
      keyComponents: <String>[
        'Central crater',
        'Molten lava',
        'Lava flow channels',
        'Volcanic rock formations',
        'Hardened lava and ash layers',
      ],
      type: 'Realistic volcanic illustration / 3D model',
      mainFocus: 'Active volcano crater and lava flow',
      purpose:
          'To show the appearance and behavior of an active volcano during or after an eruption',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 7–10',
      importance:
          'Helps learners visualize volcanic activity and understand how lava flows',
      modelAssetPath: 'assets/models/3.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic3.png',
    ),
    _ARModelItem(
      title: 'Volcanic Landscape Split in Half',
      description:
          'This image depicts a striking 3D rendering of a volcanic landscape, split down the middle and displayed side-by-side. '
          'The mountain or volcano has a rugged, textured surface with a mix of green vegetation, brown rocky areas, and patches of snow or ice. '
          'The split view allows for a detailed examination of the internal structure and composition of the volcanic formation.',
      keyComponents: <String>[
        'Varied terrain (vegetation, rock, snow/ice)',
        'Realistic textures and details',
        'Internal structure and geology',
      ],
      type: '3D rendering / model',
      mainFocus: 'Split-screen volcanic landscape',
      purpose:
          'Educational visualization of volcanic landforms and internal structure',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance:
          'Encourages closer observation and study of volcanic landforms',
      modelAssetPath: 'assets/models/4.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic4.png',
    ),
    _ARModelItem(
      title: 'Erupting Volcano with Lava Flows',
      description:
          'This image depicts a dramatic and realistic rendering of an active volcano in the midst of an eruption. The volcano\'s '
          'steep slopes are covered in dark, rugged rock formations, while bright orange and red streams of molten lava flow down the sides, '
          'creating a striking contrast. The lava appears to be erupting from the central vent at the top of the volcano, spewing out in multiple directions.',
      keyComponents: <String>[
        'Steep rocky volcanic slopes',
        'Central vent / crater',
        'Bright lava streams',
        'Atmospheric effects',
      ],
      type: 'Realistic 3D rendering / digital illustration',
      mainFocus: 'Active volcanic eruption with lava flows',
      purpose: 'To help students visualize an eruption and lava movement',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance:
          'Improves understanding of volcanic hazards and eruption dynamics',
      modelAssetPath: 'assets/models/5.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic5.png',
    ),
    _ARModelItem(
      title: 'Erupting Volcano: Power of Nature',
      description:
          'The image shows an active volcano violently erupting, releasing molten lava and thick clouds of ash into the sky. '
          'Bright streams of lava flow down the volcano\'s slopes, highlighting the intense heat and energy beneath the Earth\'s surface. '
          'The dark background emphasizes the dramatic contrast between the glowing lava and the surrounding environment.',
      keyComponents: <String>[
        'Lava flows',
        'Ash cloud',
        'Crater',
        'Volcanic cone',
      ],
      type: 'Natural phenomenon',
      mainFocus: 'Volcanic eruption',
      purpose: 'Visual aid for volcanic activity and natural hazards lessons',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance:
          'Shows the intensity of eruptions and connects to hazards and plate tectonics',
      modelAssetPath: 'assets/models/6.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic6.png',
    ),
    _ARModelItem(
      title: 'Internal Parts of a Volcano',
      description:
          'The image shows a cross-section model of a volcano highlighting its internal structure. It illustrates the pathway of magma '
          'from deep underground up to the volcanic vent. The labeled depth measurements indicate how magma originates far below the Earth\'s surface '
          'before reaching the volcano during an eruption.',
      keyComponents: <String>[
        'Magma chamber',
        'Main vent / conduit',
        'Secondary chamber / conduit',
        'Crater / opening',
        'Depth indicators',
      ],
      type: 'Scientific / Educational diagram',
      mainFocus: 'Volcano anatomy (internal structure)',
      purpose: 'To help students understand magma movement and eruptions',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance: 'Explains how eruptions originate below the Earth\'s surface',
      modelAssetPath: 'assets/models/7.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic7.png',
    ),
    _ARModelItem(
      title: 'External Parts of a Volcano',
      description:
          'The image shows the outer structure of a volcano as seen from above ground. It highlights the volcanic cone, crater at the summit, '
          'and the surrounding slopes formed by layers of solidified lava and ash. This visual focuses on the visible features of a volcano rather than its internal structure.',
      keyComponents: <String>[
        'Crater',
        'Volcanic cone',
        'Slopes / flanks',
        'Summit',
      ],
      type: 'Scientific / Educational illustration',
      mainFocus: 'Volcano anatomy (external structure)',
      purpose: 'To identify visible features of a volcano above ground',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance:
          'Supports lessons on volcano formation, lava deposition, and erosion',
      modelAssetPath: 'assets/models/8.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic8.png',
    ),
    _ARModelItem(
      title: 'Erupting Volcano with Lava Vent',
      description:
          'The image shows a volcanic mountain with a visible lava vent glowing at its side. Molten lava is exposed near the surface, '
          'emitting bright orange and yellow hues that contrast with the darker, rocky exterior of the volcano. The scene represents an active '
          'or semi-active volcanic state, emphasizing heat, magma movement, and geological intensity.',
      keyComponents: <String>[
        'Lava vent on the slope',
        'Glowing molten lava',
        'Rocky cone structure',
      ],
      type: 'Natural landform',
      mainFocus: 'Volcano with lava vent',
      purpose: 'To emphasize magma movement near the surface and heat',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance:
          'Helps learners connect surface features to underground processes',
      modelAssetPath: 'assets/models/9.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic9.png',
    ),
    _ARModelItem(
      title: 'Active Volcano with Flowing Lava Channel',
      description:
          'The image depicts an active volcano with molten lava flowing steadily from its summit crater down the slope. The lava forms a bright '
          'orange-red stream cutting through the dark, solidified volcanic rock. Surrounding terrain appears barren and rugged, shaped by previous eruptions and lava deposits.',
      keyComponents: <String>[
        'Open summit crater',
        'Visible lava flow',
        'Hardened lava fields',
      ],
      type: 'Geological / natural phenomenon',
      mainFocus: 'Active volcano with lava flow',
      purpose: 'To show ongoing volcanic activity and lava behavior',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 7–10',
      importance:
          'Supports understanding of lava channels and volcanic landforms',
      modelAssetPath: 'assets/models/10.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic10.png',
    ),
    _ARModelItem(
      title: 'Volcanic Island Eruption with Ash Plume',
      description:
          'The image illustrates a powerful volcanic eruption occurring on a small island surrounded by water. A dense column of ash and volcanic '
          'gases rises dramatically into the air, while the ocean around the island appears disturbed by heat and eruptive activity. The volcano\'s surface '
          'is rugged and fractured, indicating intense internal pressure and active magma release.',
      keyComponents: <String>[
        'Large ash and gas plume',
        'Volcanic island',
        'Turbulent water',
        'Fractured volcanic rock',
      ],
      type: 'Natural disaster / geological event',
      mainFocus: 'Island volcanic eruption with ash plume',
      purpose: 'To show explosive eruptions and ash/gas release',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance: 'Highlights eruption hazards and impacts on the environment',
      modelAssetPath: 'assets/models/11.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic11.png',
    ),
    _ARModelItem(
      title: 'Internal Structure of the Human Heart',
      description:
          'This diagram shows the internal structure of the human heart, including an Inquiry Lab activity titled "How the Heart Looks Like." '
          'Students are instructed to observe and draw the hearts of a pig, chicken, and frog, then identify at least three similarities and two differences among them. '
          'The labeled diagram shows the major anatomical structures of the heart.',
      keyComponents: <String>[
        'Larynx (voice box)',
        'Trachea (windpipe)',
        'Primary Bronchi',
        'Secondary Bronchi',
        'Tertiary Bronchi',
        'Bronchiole',
      ],
      type: 'Anatomical diagram / Educational illustration',
      mainFocus: 'Internal anatomy of the human heart',
      purpose:
          'To help students understand heart structure and comparative anatomy',
      subjectArea: 'Biology / Human Anatomy',
      gradeLevel: 'Grade 7–10',
      importance:
          'Supports understanding of cardiovascular system and comparative anatomy studies',
      modelAssetPath: 'assets/models/12.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic14.png',
    ),
    _ARModelItem(
      title: 'Anatomy of an Air Sac',
      description:
          'The diagram highlights the transition from the airway tubes to the microscopic sacs where oxygen enters the blood. '
          'It shows the bronchiole as a small branch of the airway that leads into the air sacs, acting as the final "hallway" for air before reaching the exchange site. '
          'The alveoli are individual, grape-like microscopic bulbs that are the primary sites of gas exchange.',
      keyComponents: <String>[
        'Bronchiole',
        'Alveoli',
        'Air Sac (Alveolar Sac)',
        'Arteriole (Red - oxygenated blood)',
        'Venule (Blue/Purple - deoxygenated blood)',
      ],
      type: 'Anatomical diagram / Educational illustration',
      mainFocus: 'Gas exchange structures in the lungs',
      purpose:
          'To show how oxygen and carbon dioxide are exchanged in the lungs',
      subjectArea: 'Biology / Human Anatomy',
      gradeLevel: 'Grade 7–10',
      importance:
          'Essential for understanding respiratory system and gas exchange process',
      modelAssetPath: 'assets/models/13.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic15.png',
    ),
    _ARModelItem(
      title: 'Human Respiratory Tree',
      description:
          'The diagram shows the hierarchical branching of the respiratory tract, starting from the larynx (voice box) at the top of the airway '
          'down through the trachea (windpipe), primary bronchi, secondary bronchi, tertiary bronchi, and finally the bronchioles that lead to the alveoli.',
      keyComponents: <String>[
        'Larynx',
        'Trachea',
        'Primary Bronchi',
        'Secondary Bronchi',
        'Tertiary Bronchi',
        'Bronchiole',
      ],
      type: 'Anatomical diagram / Educational illustration',
      mainFocus: 'Anatomy of the airway',
      purpose:
          'To help students understand the structure of the respiratory system',
      subjectArea: 'Biology / Human Anatomy',
      gradeLevel: 'Grade 7–10',
      importance:
          'Supports understanding of how air travels through the respiratory system',
      modelAssetPath: 'assets/models/14.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic16.png',
    ),
    _ARModelItem(
      title: 'The Structure of Homologous Chromosomes',
      description:
          'The diagram labels the critical parts of genetic structures. Homologous chromosomes are a pair of chromosomes (one from each parent) '
          'that are similar in shape, size, and genetic content. Sister chromatids are the two identical copies of a single chromosome formed during DNA replication.',
      keyComponents: <String>[
        'Homologous Chromosomes',
        'Sister Chromatids',
        'Centromere',
        'Kinetochore',
      ],
      type: 'Genetic diagram / Educational illustration',
      mainFocus: 'Chromosome structure and terminology',
      purpose:
          'To help students understand chromosome structure and cell division',
      subjectArea: 'Biology / Genetics',
      gradeLevel: 'Grade 9–10',
      importance:
          'Essential for understanding cell division, inheritance, and genetic variation',
      modelAssetPath: 'assets/models/15.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic17.png',
    ),
    _ARModelItem(
      title: 'Linear Molecular Geometry',
      description:
          'The image shows a molecule where the atoms are arranged in a straight line. The diagram explicitly shows a 180° angle between the terminal atoms. '
          'The central atom (grey sphere) is in the middle, while terminal atoms (green spheres) are on the ends. This shape occurs when the central atom has '
          'two bonding pairs and zero lone pairs of electrons.',
      keyComponents: <String>[
        'Bond Angle (180°)',
        'Central Atom',
        'Terminal Atoms',
        'VSEPR Theory',
      ],
      type: 'Molecular geometry diagram / Educational illustration',
      mainFocus: 'Linear molecular shape',
      purpose:
          'To help students understand molecular geometry and VSEPR theory',
      subjectArea: 'Chemistry',
      gradeLevel: 'Grade 9–10',
      importance:
          'Supports understanding of molecular shapes and chemical bonding',
      modelAssetPath: 'assets/models/16.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic18.png',
    ),
    _ARModelItem(
      title: 'Boron Trifluoride (BF3)',
      description:
          'A classic example of trigonal planar geometry in chemistry. The boron atom is sp² hybridized. While the B-F bonds are polar, '
          'the symmetrical shape of the molecule causes the dipole moments to cancel out, making BF₃ a nonpolar molecule. '
          'Boron is "electron-deficient" here, having only six valence electrons instead of the usual eight.',
      keyComponents: <String>[
        'Molecular Geometry: Trigonal Planar',
        'Hybridization: sp²',
        'Polarity: Nonpolar molecule',
        'Octet Rule Exception',
      ],
      type: 'Molecular structure diagram / Educational illustration',
      mainFocus: 'Trigonal planar molecular geometry',
      purpose:
          'To illustrate molecular geometry, hybridization, and polarity concepts',
      subjectArea: 'Chemistry',
      gradeLevel: 'Grade 9–10',
      importance:
          'Essential for understanding molecular shapes, polarity, and chemical bonding exceptions',
      modelAssetPath: 'assets/models/17.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic19.png',
    ),
    _ARModelItem(
      title: 'Structure and Hazards of an Erupting Volcano',
      description:
          'A cross-section diagram of an active volcano, illustrating various geological features and hazards associated with an eruption. '
          'Shows magma deep beneath the volcano, lava flows on the surface, ash flows, mud flows (lahars), landslides, eruption clouds, '
          'acid rain, and the effect of prevailing winds.',
      keyComponents: <String>[
        'Magma',
        'Dome',
        'Lava flow',
        'Ash flow (pyroclastic flow)',
        'Mud flow (lahar)',
        'Landslide',
        'Eruption cloud',
        'Acid Rain',
        'Prevailing wind',
      ],
      type: 'Geological diagram / Educational illustration',
      mainFocus: 'Volcanic structure and eruption hazards',
      purpose:
          'To help students understand volcanic hazards and eruption dynamics',
      subjectArea: 'Earth Science / Geology',
      gradeLevel: 'Grade 9',
      importance:
          'Essential for understanding volcanic hazards and disaster preparedness',
      modelAssetPath: 'assets/models/18.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic20.png',
    ),
    _ARModelItem(
      title: 'Indicators of a Warming World',
      description:
          'Uses arrows to show how different environmental factors are trending as the Earth\'s temperature rises. '
          'Shows rising tropospheric temperature, increasing humidity, warming ocean temperatures, rising sea levels, '
          'increasing ocean heat content, and rising temperatures over land.',
      keyComponents: <String>[
        'Tropospheric Temperature',
        'Humidity',
        'Temperature Over Oceans',
        'Sea Surface Temperature',
        'Sea Level',
        'Ocean Heat Content',
        'Temperature Over Land',
      ],
      type: 'Environmental diagram / Educational illustration',
      mainFocus: 'Climate change indicators',
      purpose:
          'To illustrate the effects of global warming on various environmental factors',
      subjectArea: 'Earth Science / Environmental Science',
      gradeLevel: 'Grade 7–10',
      importance:
          'Essential for understanding climate change and its environmental impacts',
      modelAssetPath: 'assets/models/19.glb',
      imageAssetPath: 'assets/images/3d Models AR/pic21.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Science Lab'),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        itemCount: _volcanoModels.length,
        itemBuilder: (context, index) {
          final item = _volcanoModels[index];
          return _ARModelCard(
            item: item,
            onViewAr: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ARModelViewerScreen(
                    title: item.title,
                    modelAssetPath: item.modelAssetPath,
                    alt: item.title,
                    autoLaunchAr: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ARModelItem {
  final String title;
  final String description;
  final List<String> keyComponents;
  final String type;
  final String mainFocus;
  final String purpose;
  final String subjectArea;
  final String gradeLevel;
  final String importance;
  final String modelAssetPath;
  final String imageAssetPath;

  const _ARModelItem({
    required this.title,
    required this.description,
    required this.keyComponents,
    required this.type,
    required this.mainFocus,
    required this.purpose,
    required this.subjectArea,
    required this.gradeLevel,
    required this.importance,
    required this.modelAssetPath,
    required this.imageAssetPath,
  });
}

class _ARModelCard extends StatelessWidget {
  final _ARModelItem item;
  final VoidCallback onViewAr;

  const _ARModelCard({
    required this.item,
    required this.onViewAr,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Image.asset(
            item.imageAssetPath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingM,
              0,
              AppConstants.paddingM,
              AppConstants.paddingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  item.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppConstants.paddingM),
                _DetailLine(label: 'Type', value: item.type),
                _DetailLine(label: 'Main Focus', value: item.mainFocus),
                _DetailLine(label: 'Purpose', value: item.purpose),
                _DetailLine(label: 'Subject Area', value: item.subjectArea),
                _DetailLine(label: 'Grade Level', value: item.gradeLevel),
                _DetailLine(label: 'Importance', value: item.importance),
                const SizedBox(height: AppConstants.paddingM),
                Wrap(
                  spacing: AppConstants.paddingS,
                  runSpacing: AppConstants.paddingS,
                  children: item.keyComponents
                      .map(
                        (c) => Chip(
                          label: Text(c),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppConstants.paddingM),
                ElevatedButton.icon(
                  onPressed: onViewAr,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
