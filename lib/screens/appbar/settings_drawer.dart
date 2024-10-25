import 'package:case_sync/screens/forms/login.dart';
import 'package:flutter/material.dart';

import '../../services/shared_pref.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(201, 201, 201, 1.000),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Add other settings or options here if needed

          // Spacer to push the logout button to the bottom
          const Spacer(),

          // Logout Button at the bottom center
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0), // Adjust as necessary
            child: ElevatedButton(
              onPressed: () async {
                await SharedPrefService.clearUser();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have been logged out successfully.'),
                  ),
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
