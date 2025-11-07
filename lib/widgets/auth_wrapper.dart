// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:mama_app/screens/onboarding_screen.dart';
// import '../screens/auth/login_screen.dart';
// import '../screens/home/home_screen.dart';

// /// Auth Wrapper - Handles automatic login based on Firebase Auth state
// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         // Show loading indicator while checking auth state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }

//         // If user is logged in, show home screen
//         if (snapshot.hasData && snapshot.data != null) {
//           return const HomeScreen();
//         }

//         // If user is not logged in, show login screen
//         return const OnboardingScreen();
//       },
//     );
//   }
// }
