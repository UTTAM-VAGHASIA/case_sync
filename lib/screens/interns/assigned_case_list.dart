import 'dart:convert';

import 'package:case_sync/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import '../../components/case_card.dart';
import '../../models/case_list.dart';

class AssignedCaseList extends StatefulWidget {
  const AssignedCaseList({super.key});

  @override
  State<AssignedCaseList> createState() => _AssignedCaseListState();
}

class _AssignedCaseListState extends State<AssignedCaseList> {
  bool _isLoading = true;
  List<Case> _assignedCases = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Case> _filteredCases = [];

  late String _errorMessage;

  @override
  void initState() {
    _errorMessage = '';
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    try {
      final url = Uri.parse('$baseUrl/get_assigned_case_list');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _assignedCases = (data['data'] as List)
                .map((item) => Case.fromJson(item))
                .toList();
            _filteredCases = List.from(_assignedCases);
            if (kDebugMode) {
              print(_filteredCases);
            }
          });
        } else {
          _showError("No cases found.");
          setState(() {
            _errorMessage = 'No cases found';
          });
        }
      } else {
        _showError("Failed to fetch cases.");
        setState(() {
          _errorMessage =
              'Failed to fetch cases due to ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      _showError("An error occurred: $e");
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
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
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
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
                HapticFeedback.mediumImpact();
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
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : (_errorMessage.isNotEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _fetchCases();
                            });
                          },
                          child: const Text('Retry')),
                    ],
                  ),
                )
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
                      child: RefreshIndicator(
                        color: Colors.black,
                        onRefresh: _fetchCases,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredCases.length,
                          itemBuilder: (context, index) {
                            final caseItem = _filteredCases[index];
                            return CaseCard(
                              caseItem: caseItem,
                              isHighlighted: false,
                              isTask: true,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
