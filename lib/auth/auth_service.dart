import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login method
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message; // return error message
    }
  }

  // Sign up method
  Future<String?> signUp(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save user role in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
      });
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unknown error occurred';
    }
  }

  // Get UID of current user
  String? getCurrentUserUid() {
    return _auth.currentUser?.uid;
  }

  // Fetch user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role']; // 'admin', 'ngo', or 'volunteer'
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
    return null;
  }
}
