// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  String? getCurrentUserUid() {
    return _auth.currentUser?.uid;
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print("✅ Fetched user role: ${data['role']}");
        return data['role'];
      } else {
        print("⚠️ No such user document found in Firestore.");
        return null;
      }
    } catch (e) {
      print("🔥 Failed to fetch user role: $e");
      return null;
    }
  }
}
