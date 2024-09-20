import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main(){
  runApp(const CaseSyncApp());
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Set the LoginScreen as the home screen
    );
  }
}