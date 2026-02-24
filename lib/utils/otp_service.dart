import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class OTPService {
  static const String _collection = 'password_reset_otps';
  static const int _otpLength = 6;
  static const int _otpExpiryMinutes = 5;

  /// Generate a random 6-digit OTP
  static String _generateOTP() {
    final random = Random();
    return List.generate(_otpLength, (_) => random.nextInt(10)).join();
  }

  /// Generate and store OTP for password reset
  /// Returns the generated OTP (in production, this would be sent via email)
  static Future<String> generateOTP(String email) async {
    final otp = _generateOTP();
    final expiryTime = DateTime.now().add(Duration(minutes: _otpExpiryMinutes));

    // Store OTP in Firestore
    await FirebaseFirestore.instance.collection(_collection).doc(email).set({
      'otp': otp,
      'expiryTime': expiryTime.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // In production, you would send this OTP via email service
    // For now, we'll return it directly for testing
    return otp;
  }

  /// Verify OTP for password reset
  static Future<bool> verifyOTP(String email, String enteredOTP) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(email)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (data == null) return false;

      final storedOTP = data['otp'] as String?;
      final expiryTimeString = data['expiryTime'] as String?;

      if (storedOTP == null || expiryTimeString == null) {
        return false;
      }

      // Check if OTP matches
      if (storedOTP != enteredOTP) {
        return false;
      }

      // Check if OTP is expired
      final expiryTime = DateTime.parse(expiryTimeString);
      if (DateTime.now().isAfter(expiryTime)) {
        // Delete expired OTP
        await FirebaseFirestore.instance
            .collection(_collection)
            .doc(email)
            .delete();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete OTP after successful password reset
  static Future<void> deleteOTP(String email) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(email)
          .delete();
    } catch (e) {
      // Ignore errors during deletion
    }
  }

  /// Check if an OTP exists for the given email
  static Future<bool> hasPendingOTP(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(email)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (data == null) return false;

      final expiryTimeString = data['expiryTime'] as String?;
      if (expiryTimeString == null) return false;

      final expiryTime = DateTime.parse(expiryTimeString);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }
}
