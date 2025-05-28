import 'package:flutter/material.dart';
import 'auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'volunteer'; // Default role

  final _authService = AuthService();

  void _signup() async {
    String? result = await _authService.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _role,
    );
    if (result == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            DropdownButtonFormField<String>(
              value: _role,
              items: ['volunteer', 'ngo', 'admin']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                  .toList(),
              onChanged: (value) => setState(() => _role = value!),
              decoration: const InputDecoration(labelText: 'Select Role'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _signup, child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}
