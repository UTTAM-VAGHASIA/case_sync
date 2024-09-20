import 'package:flutter/material.dart';
import 'login.dart'; // Import the login screen

void main() {
  runApp(const CaseSyncApp());
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Set the LoginScreen as the home screen
    );
  }
}