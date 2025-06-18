// main.dart
// Entry point for the LocalLoop Flutter app.
// This file initializes Firebase, sets up the app theme, and defines navigation routes.

import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:firebase_core/firebase_core.dart'; // Firebase core package
import 'package:localloop/firebase_options.dart'; // Firebase configuration options
import 'auth/login_screen.dart'; // Login screen widget
import 'auth/signup_screen.dart'; // Signup screen widget

// The main() function is the entry point of the app.
void main() async {
  // Ensures Flutter engine is initialized before using platform channels or plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Firebase with platform-specific options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Launches the root widget of the app.
  runApp(const MyApp());
}

// MyApp is the root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp sets up app-wide configuration: title, theme, home, and routes.
    return MaterialApp(
      title: 'LocalLoop', // App title
      theme: ThemeData(
        useMaterial3: true, // Enables Material 3 design
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Sets primary color
      ),
      home: const LoginScreen(), // Initial screen shown (login)
      routes: {
        '/login': (context) => const LoginScreen(), // Named route for login
        '/signup': (context) => const SignupScreen(), // Named route for signup
      },
    );
  }
}
