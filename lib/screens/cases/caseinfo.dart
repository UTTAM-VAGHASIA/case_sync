import 'package:flutter/material.dart';

class CaseHistoryPage extends StatefulWidget {
  const CaseHistoryPage({super.key});

  @override
  _CaseHistoryPageState createState() => _CaseHistoryPageState();
}

class _CaseHistoryPageState extends State<CaseHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedYear = '2024'; // Default year selection

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Example case data for each year and month
  final Map<String, Map<String, List<Map<String, String>>>> caseData = {
    '2024': {
      'January': [
        {'caseId': '#Case202401', 'plaintiff': 'John Doe', 'location': 'Court A'},
        {'caseId': '#Case202402', 'plaintiff': 'Jane Smith', 'location': 'Court B'},
      ],
      'February': [
        {'caseId': '#Case202403', 'plaintiff': 'John Smith', 'location': 'Court C'},
      ],
    },
    '2023': {
      'January': [
        {'caseId': '#Case202301', 'plaintiff': 'Alan Brown', 'location': 'Court D'},
      ],
      'February': [
        {'caseId': '#Case202302', 'plaintiff': 'Linda White', 'location': 'Court E'},
      ],
    },
    // Add more years with cases here...
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: months.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F3F3), // Set the background color to #f3f3f3
      appBar: AppBar(
        backgroundColor: Color(0xFFF3F3F3), // Set the app bar background to #f3f3f3
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Handle back navigation
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // Handle settings action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Spacer to position the section 15% from the top
          // SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          // Container for Title and Year Dropdown with background color #f3f3f3
          Container(
            color: Color(0xFFF3F3F3),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Case History',
                  style: TextStyle(
                    fontSize: 30, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  width: 100, // Increased width for the dropdown
                  height: 30, // Reduced height for the dropdown
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0), // Slightly rounded corners
                  ),
                  child: DropdownButton<String>(
                    value: selectedYear,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                    underline: SizedBox(),
                    isExpanded: true, // Ensure the dropdown fills the container
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedYear = newValue!;
                      });
                    },
                    dropdownColor: Colors.white,
                    items: <String>['2024', '2023', '2022', '2021']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Month TabBar with background color #f3f3f3
          Container(
            color: Color(0xFFF3F3F3), // Set the background color to #f3f3f3
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 2.0,
              labelPadding: EdgeInsets.symmetric(horizontal: 12.0), // Adjust padding for tabs
              tabs: months.map((month) => Tab(text: month)).toList(),
            ),
          ),

          // Expanded Case List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: months.map((month) {
                return ListView.builder(
                  itemCount: getCaseDataForMonth(selectedYear, month).length, // Display cases for the selected month
                  itemBuilder: (context, index) {
                    var caseItem = getCaseDataForMonth(selectedYear, month)[index];
                    return CaseCard(
                      caseId: caseItem['caseId']!,
                      plaintiff: caseItem['plaintiff']!,
                      location: caseItem['location']!,
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Fetch case data based on the selected year and month
  List<Map<String, String>> getCaseDataForMonth(String year, String month) {
    return caseData[year]?[month] ?? [];
  }
}

// Case card widget with updated separator and spacing
class CaseCard extends StatelessWidget {
  final String caseId;
  final String plaintiff;
  final String location;

  const CaseCard({super.key, required this.caseId, required this.plaintiff, required this.location});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white, // Set card background to white
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    '45',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text('Days'),
                ],
              ),
              SizedBox(width: 30), // Add this SizedBox to increase space between 45 Days and the separator
              // Updated separator to make it thicker and more visible
              Container(
                width: 2, // Increased thickness
                height: 50, // Adjusted height
                color: Colors.grey[700], // Darker grey for more visibility
              ),
              SizedBox(width: 25), // Adds space between divider and case details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caseId, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(plaintiff),
                  Text(location, style: TextStyle(color: Colors.purple)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
