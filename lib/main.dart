import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main(){
  runApp(const CaseSyncApp());
}

ThemeData customTheme() {
  return ThemeData(
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelStyle: TextStyle(color: Colors.black),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(20))
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
  );
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: customTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Set the LoginScreen as the home screen
    );
  }
}