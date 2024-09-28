import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../appbar/settings_drawer.dart';

class InternListScreen extends StatelessWidget {
  const InternListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3), // Set the background color to #f3f3f3
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 56 + 30,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 35,
                height: 35,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  scrollControlDisabledMaxHeightRatio: 5 / 6,
                  backgroundColor: Color.fromRGBO(201, 201, 201, 1),
                  builder: (context) => const SettingsDrawer(),
                );
              },
            ),
          ),
        ],
      ),

      // The main body of the page
      body: Column(
        children: [
          // Title below the AppBar
          Container(
            color: Color(0xFFF3F3F3),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Intern List',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )
              ],
            ),
          ),

          // List of interns
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 10,  // Set a higher number for demonstration (makes it scrollable)
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const InternCard(),  // Reuse the InternCard widget for each item
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InternCard extends StatelessWidget {
  const InternCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // Set card background to white
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 3,  // Adds shadow effect
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: IntrinsicHeight(  // Ensures correct height
          child: Row(
            children: [
              // Left side: Intern details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '#Intern123',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text('+91 XXXXXXXXXX'),
                    Text('intern123@gmail.com'),
                  ],
                ),
              ),

              // Vertical divider between the details and date
              const VerticalDivider(
                thickness: 1,
                color: Colors.grey,
              ),

              // Right side: Date
              const Text(
                '21-10-2024',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}