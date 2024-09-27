import 'package:flutter/material.dart';

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Black color for the button
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
              ),
              onPressed: () {
                // Call the logout functionality
                _logoutUser(context);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white, // White text
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method will handle the logout functionality
  void _logoutUser(BuildContext context) {
    // You can replace this with actual logout functionality
    // For example, if you're using Firebase Auth:
    // await FirebaseAuth.instance.signOut();

    // Navigate to the login screen or any other screen after logging out
    // Navigator.pushReplacementNamed(context, '/login');

    // Show a simple snackbar message for demo purposes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been logged out'),
      ),
    );

    // Close the modal after logging out
    Navigator.pop(context);
  }
}
