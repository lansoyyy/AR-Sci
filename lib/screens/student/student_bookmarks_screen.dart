import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';

class StudentBookmarksScreen extends StatelessWidget {
  const StudentBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: currentUser == null
          ? const Center(
              child: Text(
                'You are not logged in.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookmarks')
                  .where('userId', isEqualTo: currentUser.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load bookmarks. ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final bookmarks = snapshot.data?.docs ?? [];
                if (bookmarks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.paddingL),
                      child: Text(
                        'No bookmarks yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    final data = bookmark.data();
                    final contentType =
                        (data['contentType'] ?? data['itemType'] ?? 'lesson')
                            .toString();
                    final contentId = (data['contentId'] ??
                            data['lessonId'] ??
                            data['itemId'] ??
                            '')
                        .toString();
                    final title =
                        (data['title'] ?? data['lessonTitle'] ?? 'Untitled')
                            .toString();
                    final subtitle = [
                      (data['subject'] ?? '').toString(),
                      (data['gradeLevel'] ?? '').toString(),
                    ].where((value) => value.trim().isNotEmpty).join(' • ');

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: AppConstants.paddingM),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: contentType == 'quiz'
                              ? AppColors.warning.withOpacity(0.15)
                              : AppColors.studentPrimary.withOpacity(0.15),
                          child: Icon(
                            contentType == 'quiz'
                                ? Icons.quiz_outlined
                                : Icons.bookmark,
                            color: contentType == 'quiz'
                                ? AppColors.warning
                                : AppColors.studentPrimary,
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                        trailing: IconButton(
                          onPressed: () async {
                            await bookmark.reference.delete();
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                        onTap: contentId.isEmpty
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  contentType == 'quiz'
                                      ? '/quiz-detail'
                                      : '/lesson-detail',
                                  arguments: contentId,
                                );
                              },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
