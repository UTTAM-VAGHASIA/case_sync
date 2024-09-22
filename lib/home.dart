import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home Screen',
      theme: ThemeData(
        brightness: Brightness.light, // Light theme for white background
        scaffoldBackgroundColor: const Color.fromRGBO(243, 243, 243, 100),
        cardColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          titleLarge: TextStyle(color: Colors.black),
        ),
      ),
      home: const HomeScreen(responseBody: '',),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required String responseBody});

  @override
  Widget build(BuildContext context) {
    // Get screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine the number of columns based on screen width
    int gridCrossAxisCount = (screenWidth < 600) ? 2 : 4;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(243, 243, 243, 100),
        elevation: 0,
        leading: const Icon(Icons.notifications_none, color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              const Text(
                'Good Morning',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
              const Text(
                'Mr. Uttam Vaghasia',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 20),

              // "Cases" section
              const Text(
                'Cases',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: gridCrossAxisCount, // Responsive number of columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: (screenWidth / 2) / 120, // Adjust based on screen width
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCard('Unassigned Cases', 'assets/icons/save-remove.png', screenWidth, isAsset: true),
                  _buildCard('Assigned Cases', 'assets/icons/save-2.png', screenWidth, isAsset: true),
                  _buildCard('Case History', 'assets/icons/clock.png', screenWidth, isAsset: true),
                  _buildCard('New Case', 'assets/icons/save-add.png', screenWidth, isAsset: true),
                ],
              ),

              const SizedBox(height: 20),

              // "Interns" section
              const Text(
                'Interns',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: gridCrossAxisCount, // Responsive number of columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: (screenWidth / 2) / 120,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCard('Intern List', 'assets/icons/intern-list-icon.png', screenWidth, isAsset: true),
                  _buildCard('Tasks', 'assets/icons/clipboard-text.png', screenWidth, isAsset: true),
                ],
              ),
              const SizedBox(height: 20),

              // "Add an Official" section
              const Text(
                'Add an Official',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: gridCrossAxisCount, // Responsive number of columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: (screenWidth / 2) / 120,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCard('New Advocate', 'assets/icons/Frame 2641.png', screenWidth, isAsset: true),
                  _buildCard('New Intern', 'assets/icons/profile-add.png', screenWidth, isAsset: true),
                ],
              ),
              const SizedBox(height: 20),

              // "Companies" section
              const Text(
                'Companies',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: gridCrossAxisCount, // Responsive number of columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: (screenWidth / 2) / 120,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCard('Companies', 'assets/icons/building.png', screenWidth, isAsset: true),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Updated _buildCard function with dynamic sizing
  Widget _buildCard(String title, dynamic icon, double screenWidth, {bool isAsset = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: SizedBox(
        width: screenWidth / 2 - 20, // Set width based on screen width
        height: 120, // Set a fixed height
        child: InkWell(
          onTap: () {
            // Define actions for each card when tapped
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start (left)
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isAsset
                    ? Image.asset(icon, width: 30, height: 30)
                    : Icon(icon, size: 30, color: Colors.black),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}