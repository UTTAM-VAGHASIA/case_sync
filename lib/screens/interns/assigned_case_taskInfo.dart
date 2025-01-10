import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:case_sync/screens/interns/tasks.dart';
import '../../components/case_card.dart';
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart';

class AssignedCaseTaskinfo extends StatefulWidget {
  const AssignedCaseTaskinfo({Key? key}) : super(key: key);

  @override
  State<AssignedCaseTaskinfo> createState() => _AssignedCaseTaskinfoState();
}

class _AssignedCaseTaskinfoState extends State<AssignedCaseTaskinfo> {
  bool _isLoading = true;
  List<dynamic> _assignedCases = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _filteredCases = [];

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
            _assignedCases = data['data'];
            _filteredCases = List.from(_assignedCases);
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

  void _updateFilteredCases() {
    setState(() {
      _filteredCases = _assignedCases.where((caseItem) {
        return caseItem['case_no']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem['applicant']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem['court_name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseItem['city_name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(
        title: "Select Case",
        isSearching: _isSearching,
        onSearchPressed: () {
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TasksPage(
                                  caseNo: caseItem['case_no'],
                                ),
                              ),
                            );
                          },
                          child: CaseCard(
                            caseItem: CaseListData(
                              id: caseItem['id'].toString(),
                              caseNo: caseItem['case_no'].toString(),
                              applicant: caseItem['applicant'].toString(),
                              opponent: caseItem['opponent'] ?? 'N/A',
                              srDate: DateTime.tryParse(
                                      caseItem['sr_date'] ?? '') ??
                                  DateTime.now(),
                              courtName: caseItem['court_name'].toString(),
                              cityName: caseItem['city_name'].toString(),
                              handleBy: caseItem['handle_by'] ?? 'N/A',
                            ),
                            isHighlighted: false, // Modify as needed
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
