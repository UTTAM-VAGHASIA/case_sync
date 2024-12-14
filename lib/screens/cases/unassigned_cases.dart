import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:case_sync/screens/cases/caseinfo.dart';

class UnassignedCases extends StatefulWidget {
  const UnassignedCases({Key? key}) : super(key: key);

  @override
  State<UnassignedCases> createState() => _UnassignedCasesState();
}

class _UnassignedCasesState extends State<UnassignedCases> {
  bool _isLoading = true;
  List<Map<String, String>> _unassignedCases = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, String>> _filteredCases = [];

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/v1/index.php/get_unassigned_case_list');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _unassignedCases = (data['data'] as List)
                .map((caseItem) => {
                      "case_id": caseItem['id']?.toString() ??
                          '', // Default empty string if null
                      "case_no": caseItem['case_no']?.toString() ??
                          '', // Default empty string if null
                      "applicant": caseItem['applicant']?.toString() ??
                          'N/A', // Default to 'N/A' if null
                      "court_name": caseItem['court_name']?.toString() ??
                          'N/A', // Default to 'N/A' if null
                      "city_name": caseItem['city_name']?.toString() ??
                          'N/A', // Default to 'N/A' if null
                    })
                .toList();
            _filteredCases = List.from(_unassignedCases);
          });
        } else {
          _showError("No cases found.");
        }
      } else {
        _showError("Failed to fetch cases.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Update filtered cases when search query changes
  void _updateFilteredCases() {
    setState(() {
      _filteredCases = _unassignedCases.where((caseItem) {
        // Check if each field is not null or empty before performing search
        return (caseItem['case_no'] != null &&
                caseItem['case_no']!
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase())) ||
            (caseItem['applicant'] != null &&
                caseItem['applicant']!
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase())) ||
            (caseItem['court_name'] != null &&
                caseItem['court_name']!
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase())) ||
            (caseItem['city_name'] != null &&
                caseItem['city_name']!
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unassigned Cases",
            style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Search and Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                    _filteredCases = List.from(_unassignedCases);
                  }
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: IconButton(
              icon: const Icon(Icons.filter_alt, size: 30, color: Colors.black),
              onPressed: () {
                // Show filter modal here (implement as needed)
              },
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                                _searchQuery = value;
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
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredCases.length,
                    itemBuilder: (context, index) {
                      final caseItem = _filteredCases[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CaseInfoPage(
                                caseId: caseItem['case_id'] ??
                                    '', // Default empty string if null
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Case No: ${caseItem['case_no'] ?? ''}", // Default empty string if null
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Applicant: ${caseItem['applicant'] ?? 'N/A'}", // Default to 'N/A' if null
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Court: ${caseItem['court_name'] ?? 'N/A'}", // Default to 'N/A' if null
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "City: ${caseItem['city_name'] ?? 'N/A'}", // Default to 'N/A' if null
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
