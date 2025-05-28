class LocalUser {
  final String uid;
  final String email;
  final String role;

  LocalUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  factory LocalUser.fromMap(Map<String, dynamic> data) {
    return LocalUser(
      uid: data['uid'],
      email: data['email'],
      role: data['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
    };
  }
}
