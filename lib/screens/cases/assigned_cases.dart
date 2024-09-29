import 'package:flutter/material.dart';
import '../../components/filter_modal.dart';
import '../../components/list_app_bar.dart';
import '../../services/case_services.dart';

class AssignedCasesScreen extends StatefulWidget {
  const AssignedCasesScreen({super.key});

  @override
  _AssignedCasesScreenState createState() => _AssignedCasesScreenState();
}

class _AssignedCasesScreenState extends State<AssignedCasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedYear = '2024';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, String>> _filteredCases = [];
  int _currentResultIndex = 0;
  List<String> _resultTabs = [];

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: months.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Update filtered cases across all months
  void _updateFilteredCases() {
    setState(() {
      _filteredCases.clear();
      _resultTabs.clear();
      AssignedCaseData[selectedYear]?.forEach((month, cases) {
        final results = cases.where((caseItem) {
          return caseItem['caseId']!.toLowerCase().contains(_searchQuery) ||
              caseItem['plaintiff']!.toLowerCase().contains(_searchQuery) ||
              caseItem['assignedTo']!.toLowerCase().contains(_searchQuery);
        }).toList();

        if (results.isNotEmpty) {
          _filteredCases.addAll(results);
          _resultTabs.addAll(List.filled(results.length, month));
        }
      });
      _currentResultIndex = 0; // Reset the index when search changes

      // If there is exactly one result, navigate to the corresponding tab
      if (_filteredCases.length == 1) {
        _switchTabToResult();
      }
    });
  }

  // Navigate to previous search result
  void _navigateToPreviousResult() {
    setState(() {
      if (_currentResultIndex > 0) {
        _currentResultIndex--;
        _switchTabToResult();
      }
    });
  }

  // Navigate to next search result
  void _navigateToNextResult() {
    setState(() {
      if (_currentResultIndex < _filteredCases.length - 1) {
        _currentResultIndex++;
        _switchTabToResult();
      }
    });
  }

  void _switchTabToResult() {
    String resultMonth = _resultTabs[_currentResultIndex];
    int monthIndex = months.indexOf(resultMonth);
    _tabController.animateTo(monthIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: ListAppBar(
        onSearchPressed: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
              _searchQuery = '';
              _filteredCases = [];
              _resultTabs = [];
            }
          });
        },
        isSearching: _isSearching,
        onFilterPressed: () => FilterModal.showFilterModal(context),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _updateFilteredCases();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search cases...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentResultIndex > 0
                            ? _navigateToPreviousResult
                            : _switchTabToResult,
                      ),
                      Text(
                          '${_filteredCases.isEmpty ? 0 : _currentResultIndex + 1} / ${_filteredCases.length}'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed:
                            _currentResultIndex < _filteredCases.length - 1
                                ? _navigateToNextResult
                                : _switchTabToResult,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // "Assigned Cases" title below the AppBar
          Container(
            color: const Color(0xFFF3F3F3),
            padding:
            const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assigned Cases',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedYear,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  underline: const SizedBox(),
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
                      child: Text(value,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // List of assigned cases
          Container(
            color: const Color(0xFFF3F3F3),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 2.0,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              tabs: months.map((month) => Tab(text: month)).toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: TabBarView(
                controller: _tabController,
                children: months.map((month) {
                  var allCases = getAssignedCaseDataForMonth(selectedYear, month);
                  return ListView.builder(
                    itemCount: allCases.length,
                    itemBuilder: (context, index) {
                      var caseItem = allCases[index];

                      bool isHighlighted = _isSearching &&
                          _filteredCases.isNotEmpty &&
                          _resultTabs[_currentResultIndex] == month &&
                          _filteredCases[_currentResultIndex]['caseId'] ==
                              caseItem['caseId'];

                      return CaseCard(
                        caseId: caseItem['caseId']!,
                        plaintiff: caseItem['plaintiff']!,
                        assignedTo: caseItem['assignedTo']!,
                        isHighlighted: isHighlighted,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CaseCard extends StatelessWidget {
  final String caseId;
  final String plaintiff;
  final String assignedTo;
  final bool isHighlighted;

  const CaseCard({super.key,
    required this.caseId,
    required this.plaintiff,
    required this.assignedTo,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isHighlighted ? Colors.black : Colors.white, // Set card background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0), // More rounded corners
      ),
      elevation: 3, // Adds shadow effect like in InternCard
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 16.0), // Decreased padding to reduce card height
        child: IntrinsicHeight(
          // Ensures correct height
          child: Row(
            children: [
              // Left side: Days Column with centered text and margin from the divider
              Container(
                margin: const EdgeInsets.only(
                    right:
                        12.0), // Added margin between counter and vertical divider
                child: Column(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Center align content vertically
                  children: [
                    Text(
                      "45", // Example days remaining
                      style:
                          TextStyle(fontSize: 20, color: isHighlighted ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    ),
                    Text("Days", style: TextStyle(fontSize: 16, color: isHighlighted ? Colors.white : Colors.black,)),
                  ],
                ),
              ),

              // Vertical divider between the counter and case details
              VerticalDivider(
                thickness: 1,
                color: isHighlighted ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 12), // Right margin
              // Middle: Case Information

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: 2), // Add margin above the case information
                    Text(
                      caseId, // Example case number
                      style:
                          TextStyle(fontSize: 18, color: isHighlighted ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(plaintiff, style: TextStyle(color: isHighlighted ? Colors.white : Colors.black,),), // Example plaintiff name
                    SizedBox(height: 4),
                    Text(
                      "Assigned to: $assignedTo", // Example assignment
                      style: TextStyle(fontSize: 14, color: isHighlighted ? Colors.white : Colors.grey,),
                    ),
                  ],
                ),
              ),

              // Right side: Date inside a larger circle with margin and padding
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                        15.0), // Increased padding for larger circle
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                      isHighlighted ? Colors.white : Color(0xFFD9D9D9), // Changed color to #D9D9D9
                    ),
                    child: Column(
                      children: const [
                        Text(
                          "20", // Example date
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        Text(
                          "Sep", // Example month
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
