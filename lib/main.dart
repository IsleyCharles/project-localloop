import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Import your screens
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalLoop',
      theme: ThemeData(
        useMaterial3: true, // Material 3 for modern UI
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      
      // 👇👇👇 Set initial screen and routes
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}
