import 'dart:convert';

import 'package:case_sync/screens/interns/tasks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/case_list.dart';
import 'add_tasks.dart';

class AssignedCaseTaskinfo extends StatefulWidget {
  const AssignedCaseTaskinfo({Key? key}) : super(key: key);

  @override
  State<AssignedCaseTaskinfo> createState() => _AssignedCaseTaskinfoState();
}

class _AssignedCaseTaskinfoState extends State<AssignedCaseTaskinfo> {
  bool _isLoading = true;
  List<CaseListData> _assignedCases = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<CaseListData> _filteredCases = [];

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
            _assignedCases = (data['data'] as List)
                .map((caseItem) => CaseListData(
                    id: caseItem['id']?.toString() ?? '',
                    caseNo: caseItem['case_no']?.toString() ?? '',
                    applicant: caseItem['applicant']?.toString() ?? 'N/A',
                    courtName: caseItem['court_name']?.toString() ?? 'N/A',
                    cityName: caseItem['city_name']?.toString() ?? 'N/A',
                    handleBy: '',
                    opponent: '',
                    srDate: DateTime(2025)))
                .toList();
            _filteredCases = List.from(_assignedCases);
            if (kDebugMode) {
              print(_filteredCases);
            }
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
      _filteredCases = _assignedCases.where((caseItem) {
        return caseItem.caseNo
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem.applicant
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem.courtName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem.cityName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Case",
            style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
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
                    _filteredCases = List.from(_assignedCases);
                  }
                });
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
                              builder: (context) => TasksPage(
                                caseNumber: caseItem.caseNo,
                                caseNo: caseItem.id,
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
                                  "Case No: ${caseItem.caseNo}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Applicant: ${caseItem.applicant}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Court: ${caseItem.courtName}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "City: ${caseItem.cityName}",
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
