import 'package:flutter/material.dart';

class UnassignedCases extends StatelessWidget {
  const UnassignedCases({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3), // Set the app bar background to #f3f3f3
        elevation: 0, // Remove shadow under the AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,size: 35,color: Colors.black,),
          onPressed: () {
            // Action for back button
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings,size: 35,color: Colors.black,),
            onPressed: () {
              // Action for settings button
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF3F3F3), // Set background color to #f3f3f3
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Assigned Cases" title below the AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              children: const [
                Text(
                  'Unassigned Cases',
                  style: TextStyle(
                    fontSize: 30, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // List of assigned cases
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 10, // Example count for the list
              itemBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0), // Same vertical padding as in InternCard
                  child: CaseCard(), // Reuse the CaseCard widget
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CaseCard extends StatelessWidget {
  const CaseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // Set card background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0), // More rounded corners
      ),
      elevation: 3, // Adds shadow effect like in InternCard
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Decreased padding to reduce card height
        child: IntrinsicHeight( // Ensures correct height
          child: Row(
            children: [
              // Left side: Days Column with centered text and margin from the divider
              Container(
                margin: const EdgeInsets.only(right: 12.0), // Added margin between counter and vertical divider
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center align content vertically
                  children: const [
                    Text(
                      "45", // Example days remaining
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Reduced size of days counter
                    ),
                    Text("Days", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),

              // Vertical divider between the counter and case details
              const VerticalDivider(
                thickness: 1,
                color: Colors.grey,
              ),

              // Add margin to the right of the vertical divider
              const SizedBox(width: 12), // Right margin

              // Middle: Case Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 2), // Add margin above the case information
                    Text(
                      "#Case123", // Example case number
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4), // Reduced spacing
                    Text("CompanyName"),
                    SizedBox(height: 4), // Space between case info and vertical divider
                    Text(
                      "Surat/CourtName", // Example assignment
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Right side: Removed date
            ],
          ),
        ),
      ),
    );
  }
}
