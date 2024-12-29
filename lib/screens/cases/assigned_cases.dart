import 'dart:convert';

import 'package:case_sync/screens/cases/caseinfo.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AssignedCases extends StatefulWidget {
  const AssignedCases({Key? key}) : super(key: key);

  @override
  State<AssignedCases> createState() => _AssignedCasesState();
}

class _AssignedCasesState extends State<AssignedCases> {
  bool _isLoading = true;
  List<Map<String, String>> _AssignedCases = [];
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
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_assigned_case_list');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _AssignedCases = (data['data'] as List)
                .map((caseItem) => {
                      "case_id": caseItem['id']
                          .toString(), // Ensure correct field for case_id
                      "case_no": caseItem['case_no'].toString(),
                      "applicant": caseItem['applicant'].toString(),
                      "court_name": caseItem['court_name'].toString(),
                      "city_name": caseItem['city_name'].toString(),
                    })
                .toList();
            _filteredCases = List.from(_AssignedCases);
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
      _filteredCases = _AssignedCases.where((caseItem) {
        return caseItem['case_no']!
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem['applicant']!
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem['court_name']!
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem['city_name']!
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Cases",
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
                    _filteredCases = List.from(_AssignedCases);
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
                                caseId:
                                    caseItem['case_id']!, // Pass case_id here
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
                                  "Case No: ${caseItem['case_no']}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Applicant: ${caseItem['applicant']}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Court: ${caseItem['court_name']}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "City: ${caseItem['city_name']}",
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
