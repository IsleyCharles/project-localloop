import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Register User
  Future<String?> signUp(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = result.user!;
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'role': role,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Sign In User
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Get Current User Role
  Future<String?> getUserRole(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'];
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
