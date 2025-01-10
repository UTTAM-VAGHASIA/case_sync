import 'package:case_sync/models/advocate.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/material.dart';

import '../forms/login.dart';

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
      child: Stack(
        children: [
          // Background Logo
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Center(
                child: Image.asset(
                  'assets/icons/app_icon.png', // Replace with your actual logo path
                  width: screenWidth * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: FutureBuilder<Advocate?>(
                  future: SharedPrefService.getUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Text('Error loading user data');
                    } else if (snapshot.hasData && snapshot.data != null) {
                      Advocate user = snapshot.data!;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade300,
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Text(
                                'Advocate',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return const Text('User not found');
                    }
                  },
                ),
              ),

              const Spacer(),

              // Centered Logout Button
              Center(
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
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Logout'),
                ),
              ),

              const SizedBox(height: 30), // Add some space below the button
            ],
          ),
        ],
      ),
    );
  }
}
