import 'package:ar_sci/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'routes/app_routes.dart';
import 'models/user_model.dart';

Future<void> _ensureDefaultAdminExists() async {
  try {
    final db = FirebaseFirestore.instance;

    // Check if default admin already exists
    final adminQuery = await db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (adminQuery.docs.isEmpty) {
      // Create default admin account in Firebase Auth
      final auth = FirebaseAuth.instance;
      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: 'admin@arsci.com',
          password: 'admin123',
        );

        // Create admin user document in Firestore
        final adminUser = UserModel(
          id: credential.user!.uid,
          name: 'Administrator',
          email: 'admin@arsci.com',
          role: 'admin',
          createdAt: DateTime.now(),
        );

        await db.collection('users').doc(credential.user!.uid).set({
          ...adminUser.toJson(),
          'verified': true,
        });

        debugPrint('Default admin account created successfully');
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') {
          debugPrint('Error creating default admin: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('Error ensuring default admin exists: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Ensure default admin account exists
    await _ensureDefaultAdminExists();
  } catch (e) {
    // Log the error but continue running the app
    // Firebase services won't work, but the app will still launch
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const ARSciApp());
}

class ARSciApp extends StatelessWidget {
  const ARSciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: AppRoutes.getRoutes(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}
