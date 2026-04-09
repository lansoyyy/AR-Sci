import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSession {
  static const String adminEmail = 'admin@lcct.edu.ph';
  static const String adminPassword = 'Admin1234!';
  static const String adminUserId = 'hardcoded_admin';
  static const String adminName = 'Administrator';
  static const String adminRole = 'admin';

  static const String _hardcodedAdminSignedInKey = 'hardcoded_admin_signed_in';

  static Future<void> signInHardcodedAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hardcodedAdminSignedInKey, true);
  }

  static Future<void> clearHardcodedAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hardcodedAdminSignedInKey);
  }

  static Future<bool> isHardcodedAdminSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hardcodedAdminSignedInKey) ?? false;
  }

  static Future<bool> isEffectiveAdminSession() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return isHardcodedAdminSignedIn();
    }

    return false;
  }

  static Future<String?> resolveActorId({String? role}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }

    final normalizedRole = role?.trim().toLowerCase();
    if (normalizedRole == adminRole && await isHardcodedAdminSignedIn()) {
      return adminUserId;
    }

    return null;
  }

  static Future<String> resolveActorName({String? role}) async {
    final normalizedRole = role?.trim().toLowerCase();
    if (normalizedRole == adminRole && await isHardcodedAdminSignedIn()) {
      return adminName;
    }

    return currentFirebaseDisplayName() ?? adminName;
  }

  static String? currentFirebaseDisplayName() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final name = currentUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return null;
  }

  static Future<void> signOutAdminSession() async {
    await clearHardcodedAdminSession();

    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
