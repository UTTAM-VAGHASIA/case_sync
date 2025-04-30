import 'dart:async';
import 'dart:io';

import 'package:case_sync/check_update.dart';
import 'package:case_sync/utils/flavor_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your actual destination screens
import 'forms/login.dart';
import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the *single* initialization sequence
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    // --- Step 1: Perform Update Check (if applicable) ---
    bool canProceed =
        true; // Assume we can proceed unless blocked by update check
    // Use mounted check WITHIN async gaps if possible, definitely before context use
    if (mounted && (GetPlatform.isAndroid || Platform.isAndroid) && kReleaseMode) {
      print("Splash: Starting update check...");
      // Pass the SplashScreen's context, await the result
      canProceed = await CheckUpdate.checkForUpdate(context);
      print("Splash: Update check finished. Can proceed: $canProceed");
    } else {
      print("Splash: Skipping update check (not Android or not mounted).");
    }

    // --- Step 2: Check Login Status *ONLY IF* Update Check Allows ---
    // Also ensure widget is still mounted before potentially navigating
    if (canProceed && mounted) {
      print("Splash: Proceeding to login check...");
      await _checkLoginStatusAndNavigate();
    } else if (!canProceed && mounted) {
      print("Splash: Update check blocked further navigation.");
      // CheckUpdate should handle forced exit if needed.
      // No further action needed here, dialog should remain or app exited.
    } else {
      print("Splash: Widget unmounted during checks. Aborting navigation.");
    }
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    // Optional: Add a slight delay *here* if you still want a minimum splash time
    // await Future.delayed(const Duration(seconds: 1)); // Example: 1 second minimum

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');

    // Ensure widget is *still* mounted before navigating
    if (!mounted) {
      print("Splash: Widget unmounted before navigation.");
      return;
    }

    if (userData != null) {
      print("Splash: User logged in. Navigating to Home.");
      // User is logged in, navigate to HomeScreen
      Get.offAll(() => const HomeScreen()); // Use offAll to clear splash screen
    } else {
      print("Splash: User not logged in. Navigating to Login.");
      // User is not logged in, navigate to LoginScreen
      Get.offAll(() => LoginScreen()); // Use offAll to clear splash screen
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep your existing splash screen UI
    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1.00),
      body: Stack(
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/icons/splash_logo.svg'),
                const Text(
                  'For Advocates',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                // Optionally add a loading indicator if checks take time
                const SizedBox(height: 30),
                const CircularProgressIndicator(color: Colors.black54),
                const SizedBox(height: 10),
                const Text("Initializing...",
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          // Add flavor indicator in staging mode
          if (FlavorConfig.isTest())
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'STAGING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
