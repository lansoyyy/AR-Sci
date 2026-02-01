import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  Map<String, dynamic> _lesson = {};
  bool _isLoading = true;
  bool _isBookmarked = false;
  double _progress = 0.0;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonData() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      Map<String, dynamic> lessonData;

      if (args is Map<String, dynamic>) {
        lessonData = args;
      } else if (args is String) {
        // Fetch lesson from Firestore by ID
        final doc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(args)
            .get();
        if (doc.exists) {
          lessonData = doc.data() ?? {};
          lessonData['id'] = doc.id;
        } else {
          lessonData = {};
        }
      } else {
        lessonData = {};
      }

      if (!mounted) return;

      setState(() {
        _lesson = lessonData;
        _isLoading = false;
      });

      await _loadProgressAndBookmark();
    } catch (e) {
      debugPrint('Error loading lesson: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProgressAndBookmark() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final lessonId = _lesson['id']?.toString() ?? '';
      if (lessonId.isEmpty) return;

      // Load progress
      final progressDoc = await FirebaseFirestore.instance
          .collection('lesson_progress')
          .doc('${user.uid}_$lessonId')
          .get();

      if (progressDoc.exists) {
        final data = progressDoc.data();
        if (data != null) {
          setState(() {
            _progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
          });
        }
      }

      // Load bookmark status
      final bookmarkDoc = await FirebaseFirestore.instance
          .collection('bookmarks')
          .where('userId', isEqualTo: user.uid)
          .where('lessonId', isEqualTo: lessonId)
          .limit(1)
          .get();

      setState(() {
        _isBookmarked = bookmarkDoc.docs.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error loading progress/bookmark: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to bookmark.')),
        );
        return;
      }

      final lessonId = _lesson['id']?.toString() ?? '';
      if (lessonId.isEmpty) return;

      if (_isBookmarked) {
        // Remove bookmark
        final bookmarkQuery = await FirebaseFirestore.instance
            .collection('bookmarks')
            .where('userId', isEqualTo: user.uid)
            .where('lessonId', isEqualTo: lessonId)
            .limit(1)
            .get();

        for (var doc in bookmarkQuery.docs) {
          await doc.reference.delete();
        }

        setState(() => _isBookmarked = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark removed')),
        );
      } else {
        // Add bookmark
        await FirebaseFirestore.instance.collection('bookmarks').add({
          'userId': user.uid,
          'lessonId': lessonId,
          'lessonTitle': _lesson['title'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isBookmarked = true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson bookmarked')),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _saveProgress(double progress) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final lessonId = _lesson['id']?.toString() ?? '';
      if (lessonId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('lesson_progress')
          .doc('${user.uid}_$lessonId')
          .set({
        'userId': user.uid,
        'lessonId': lessonId,
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': progress >= 1.0 ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));

      setState(() => _progress = progress);
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _markAsComplete() async {
    await _saveProgress(1.0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesson marked as complete!')),
    );
  }

  Color _getSubjectColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'physics':
        return AppColors.studentPrimary;
      case 'chemistry':
        return AppColors.warning;
      case 'biology':
        return AppColors.success;
      case 'math':
        return AppColors.info;
      default:
        return AppColors.studentPrimary;
    }
  }

  String _subjectToColorName(String? subject) {
    if (subject == null) return 'physics';
    switch (subject.toLowerCase()) {
      case 'physics':
        return 'physics';
      case 'chemistry':
        return 'chemistry';
      case 'biology':
        return 'biology';
      case 'mathematics':
      case 'math':
        return 'math';
      default:
        return 'physics';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _getSubjectColor(
            _lesson['color'] ?? _subjectToColorName(_lesson['subject']),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_lesson.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.studentPrimary,
        ),
        body: const Center(
          child: Text(
            'Lesson not found.',
            style: TextStyle(fontSize: AppConstants.fontL),
          ),
        ),
      );
    }

    final contentText =
        _lesson['content'] is String ? (_lesson['content'] as String).trim() : '';
    final Color subjectColor = _getSubjectColor(
      _lesson['color'] ?? _subjectToColorName(_lesson['subject']),
    );
    final imageUrls = _lesson['imageUrls'] as List? ?? [];
    final videoUrls = _lesson['videoUrls'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson['title'] ?? 'Lesson'),
        backgroundColor: subjectColor,
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Video
            if (videoUrls.isNotEmpty)
              _buildVideoPlayer(videoUrls.first.toString(), subjectColor)
            else if (imageUrls.isNotEmpty)
              _buildImageHeader(imageUrls.first.toString(), subjectColor)
            else
              _buildPlaceholderHeader(subjectColor),

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
                          _lesson['subject'] ?? '',
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
                          _lesson['gradeLevel'] ?? _lesson['grade'] ?? '',
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
                    _lesson['title'] ?? '',
                    style: const TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingM),

                  // Description
                  Text(
                    _lesson['description'] ?? '',
                    style: const TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  if (contentText.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.paddingL),
                    const Text(
                      'Lesson Content',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      contentText,
                      style: const TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],

                  // Additional Images
                  if (imageUrls.length > 1) ...[
                    const SizedBox(height: AppConstants.paddingXL),
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < imageUrls.length - 1
                                  ? AppConstants.paddingM
                                  : 0,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusM),
                              child: Image.network(
                                imageUrls[index].toString(),
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    color: AppColors.surfaceLight,
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // AR Section (if applicable)
                  if (_lesson['arModelUrl'] != null &&
                      _lesson['arModelUrl'].toString().isNotEmpty) ...[
                    const SizedBox(height: AppConstants.paddingXL),
                    Card(
                      color: subjectColor.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(Icons.view_in_ar, color: subjectColor),
                        title: const Text(
                          'View in AR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Experience this lesson in augmented reality',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/ar-view',
                            arguments: _lesson,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Progress Section
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Progress',
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          fontWeight: FontWeight.bold,
                          color: subjectColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusRound),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final newProgress = (_progress + 0.25).clamp(0.0, 1.0);
                            _saveProgress(newProgress);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: subjectColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Mark Progress'),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _progress >= 1.0 ? null : _markAsComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: subjectColor,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Mark Complete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Notes Section
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Notes',
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add your notes here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Save notes functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notes saved!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                        foregroundColor: AppColors.textWhite,
                      ),
                      child: const Text('Save Notes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl, Color subjectColor) {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 80,
              color: AppColors.textWhite,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Video Available',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: AppConstants.fontL,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(String imageUrl, Color subjectColor) {
    return Container(
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
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 80,
              color: AppColors.textWhite,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderHeader(Color subjectColor) {
    return Container(
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
          Icons.book_outlined,
          size: 80,
          color: AppColors.textWhite,
        ),
      ),
    );
  }
}
