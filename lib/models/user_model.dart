// user_model.dart
// Defines the LocalUser model for representing user data in the app.

class LocalUser {
  final String uid; // User's unique ID
  final String email; // User's email address
  final String role; // User's role (admin, ngo, volunteer, etc.)

  // Constructor for LocalUser
  LocalUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  // Creates a LocalUser from a map (e.g., Firestore document)
  factory LocalUser.fromMap(Map<String, dynamic> data) {
    return LocalUser(
      uid: data['uid'],
      email: data['email'],
      role: data['role'],
    );
  }

  // Converts a LocalUser to a map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
    };
  }
}
