import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/admin_dashboard.dart';
import '../screens/ngo_dashboard.dart';
import '../screens/volunteer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  void _login() async {
    String? result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (result == null) {
  String? role = await _authService.getUserRole(
    _authService._auth.currentUser!.uid,
  );

  // Navigate based on role
  if (role == 'admin') {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
  } else if (role == 'ngo') {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NGODashboard()));
  } else {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VolunteerDashboard()));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}
