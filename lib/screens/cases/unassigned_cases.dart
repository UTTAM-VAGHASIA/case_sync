import 'package:flutter/material.dart';

class FilterModal {
  static void showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Center(
            child: Text(
              'Filter options here',
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
      },
    );
  }
}

class UnassignedCases extends StatefulWidget {
  const UnassignedCases({super.key});

  @override
  State<UnassignedCases> createState() => _UnassignedCasesState();
}

class _UnassignedCasesState extends State<UnassignedCases> {
  bool _isSearching = false; // Search bar toggle
  final TextEditingController _searchController = TextEditingController(); // Controller for search input
  String _searchQuery = ''; // Stores the current search query
  List<Map<String, String>> _filteredCases = []; // Stores filtered cases
  List<Map<String, String>> _unassignedCases = []; // Example unassigned cases list
  FocusNode _searchFocusNode = FocusNode(); // Focus node for search bar

  @override
  void initState() {
    super.initState();
    // Example unassigned cases data
    _unassignedCases = [
      {"caseId": "Case123", "company": "Company A", "location": "Surat"},
      {"caseId": "Case456", "company": "Company B", "location": "CourtName"},
      {"caseId": "Case789", "company": "Company C", "location": "Mumbai"},
    ];
    _filteredCases = List.from(_unassignedCases); // Initially show all cases
  }

  @override
  void dispose() {
    _searchController.dispose(); // Clean up the controller
    _searchFocusNode.dispose(); // Dispose of the focus node
    super.dispose();
  }

  // Update filtered cases based on search query
  void _updateFilteredCases() {
    setState(() {
      _filteredCases = _unassignedCases.where((caseItem) {
        return caseItem['caseId']!.toLowerCase().contains(_searchQuery) ||
            caseItem['company']!.toLowerCase().contains(_searchQuery) ||
            caseItem['location']!.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  // Toggle search bar and clear search
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching; // Toggle the search state
      if (_isSearching) {
        _searchFocusNode.requestFocus(); // Automatically focus the search field when search is toggled on
      } else {
        _searchController.clear();
        _searchQuery = '';
        _filteredCases = List.from(_unassignedCases); // Reset to original cases when search is turned off
        _dismissKeyboard(); // Also dismiss keyboard when search is turned off
      }
    });
  }

  // Navigate back to home screen
  void _navigateToHome() {
    Navigator.pop(context); // Navigate back to the previous screen
  }

  // Dismiss keyboard and search bar when clicking outside the search field
  void _dismissKeyboard() {
    setState(() {
      _isSearching = false; // Close search bar when tapping outside
    });
    FocusScope.of(context).unfocus(); // Remove focus from the search field
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard, // Tap anywhere outside search to dismiss keyboard and search bar
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F3F3), // Set the app bar background to #f3f3f3
          surfaceTintColor: Colors.transparent,
          elevation: 0, // Remove shadow under the AppBar
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: _navigateToHome, // Navigate to home screen on back arrow click
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search, // Change icon based on searching state
                size: 35,
                color: Colors.black,
              ),
              onPressed: _toggleSearch, // Toggle search bar
            ),
            IconButton(
              icon: const Icon(Icons.filter_list_alt, size: 35, color: Colors.black),
              onPressed: () => FilterModal.showFilterModal(context), // Call showFilterModal when filter icon is pressed
            ),
          ],
          title: _isSearching
              ? TextField(
            controller: _searchController,
            focusNode: _searchFocusNode, // Attach the focus node to automatically show the keyboard
            decoration: const InputDecoration(
              hintText: 'Search cases...',
              border: InputBorder.none,
            ),
            autofocus: true, // Auto-focus the search field when search is active
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
              _updateFilteredCases(); // Update cases as user types
            },
          )
              : null, // No title for the AppBar when not searching
        ),
        backgroundColor: const Color(0xFFF3F3F3), // Set background color to #f3f3f3
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter icon and "Unassigned Cases" title in separate rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 5), // Space between filter icon and title
                  Text(
                    'Unassigned Cases',
                    style: TextStyle(
                      fontSize: 30, // Font size for title
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // List of unassigned cases
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _filteredCases.length, // Show filtered cases
                itemBuilder: (context, index) {
                  final caseItem = _filteredCases[index]; // Get the case item
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Same vertical padding as in InternCard
                    child: CaseCard(
                      caseId: caseItem['caseId']!,
                      companyName: caseItem['company']!,
                      location: caseItem['location']!,
                    ), // Pass case data to CaseCard
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaseCard extends StatelessWidget {
  final String caseId;
  final String companyName;
  final String location;

  const CaseCard({
    Key? key,
    required this.caseId,
    required this.companyName,
    required this.location,
  }) : super(key: key);

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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

              const SizedBox(width: 12), // Right margin

              // Middle: Case Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2), // Add margin above the case information
                    Text(
                      "#$caseId", // Case number
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4), // Space between case ID and company name
                    Text(
                      companyName, // Company name
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4), // Space between company name and location
                    Text(
                      location, // Location
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
