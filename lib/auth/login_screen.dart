import 'package:flutter/material.dart';
import '../auth/auth_service.dart'; 
import '../screens/admin_dashboard.dart';
import '../screens/ngo_dashboard.dart';
import '../screens/volunteer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    String? result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (result == null) {
      String? role = await _authService.getUserRole(
        _authService.getCurrentUserUid()!,
      );

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else if (role == 'ngo') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NGODashboard()));
      } else if (role == 'volunteer') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VolunteerDashboard()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown role.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
