// auth_service.dart
// Provides authentication and user role management for the app.
// Uses Firebase Authentication and Firestore for user data.

// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication package
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database package

// AuthService encapsulates authentication and user role logic.
class AuthService {
  // FirebaseAuth instance for handling authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // FirebaseFirestore instance for accessing user data.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Logs in a user with email and password.
  // Returns null on success, or an error message on failure.
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  // Returns the UID of the currently logged-in user, or null if not logged in.
  String? getCurrentUserUid() {
    return _auth.currentUser?.uid;
  }

  // Fetches the user's role from Firestore using their UID.
  // Returns the role as a string, or null if not found or on error.
  Future<String?> getUserRole(String uid) async {
    try {
      print('Fetching user role for uid: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      print('Document exists:  ${doc.exists}');
      print('Document data:  ${doc.data()}');
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
    return null;
  }
}
