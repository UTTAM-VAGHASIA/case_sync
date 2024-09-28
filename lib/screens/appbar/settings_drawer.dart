import 'package:case_sync/screens/forms/login.dart';
import 'package:flutter/material.dart';
import 'package:case_sync/api_response/shared_pref.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

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
                // Call the logOut method from SharedPrefService
                await SharedPrefService.logOut();

                // Show snackbar after logging out successfully
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have been logged out successfully.'),
                  ),
                );

                // Navigate to the LoginScreen after successful logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  // This method will handle the logout functionality (Optional if more logic is needed)
  void _logoutUser(BuildContext context) {
    // Close the modal after logging out
    Navigator.pop(context);

    // Show a simple snackbar message for demo purposes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been logged out'),
      ),
    );
  }
}
