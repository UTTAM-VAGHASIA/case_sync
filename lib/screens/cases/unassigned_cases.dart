import 'dart:convert';

import 'package:case_sync/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../components/case_card.dart'; // Import CaseCard widget
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart'; // Import CaseListData model

class UnassignedCases extends StatefulWidget {
  const UnassignedCases({super.key});

  @override
  State<UnassignedCases> createState() => UnassignedCasesState();
}

class UnassignedCasesState extends State<UnassignedCases> {
  bool _isLoading = true;
  List<Case> _unassignedCases = [];
  List<Case> _filteredCases = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedCity;
  String? _selectedCourt;
  final List<String> _cities = [];
  final List<String> _courts = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _errorMessage = '';
    if (_unassignedCases.isEmpty) fetchCases();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _updateFilteredCases();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> fetchCases([bool isOnPage = true]) async {
    try {
      final url = Uri.parse('$baseUrl/get_unassigned_case_list');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _unassignedCases = (data['data'] as List)
              .map((item) => Case.fromJson(item))
              .toList();
          if (isOnPage) {
            setState(() {
              _filteredCases = List.from(_unassignedCases);

              _cities.addAll(
                _unassignedCases.map((caseItem) => caseItem.cityName).toSet(),
              );
              _courts.addAll(
                _unassignedCases.map((caseItem) => caseItem.courtName).toSet(),
              );
            });
          }
          return _unassignedCases.length;
        } else {
          _showError("No cases found.");
          if (isOnPage) {
            setState(() {
              _errorMessage = 'No cases found';
            });
          }
        }
      } else {
        _showError("Failed to fetch cases.");
        if (isOnPage) {
          setState(() {
            _errorMessage =
                'Failed to fetch cases due to ${response.statusCode}: ${response.body}';
          });
        }
      }
    } catch (e) {
      _showError("An error occurred: $e");
      if (isOnPage) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      }
    } finally {
      if (isOnPage) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    return 0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _updateFilteredCases() {
    setState(() {
      _filteredCases = _unassignedCases.where((caseItem) {
        final matchesSearchQuery = caseItem.caseNo
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

        final matchesCity = _selectedCity == null ||
            _selectedCity == 'All' ||
            caseItem.cityName == _selectedCity;
        final matchesCourt = _selectedCourt == null ||
            _selectedCourt == 'All' ||
            caseItem.courtName == _selectedCourt;

        return matchesSearchQuery && matchesCity && matchesCourt;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCity = null;
      _selectedCourt = null;
      _filteredCases = List.from(_unassignedCases);
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Search by case number, applicant, court or city',
          hintStyle: TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(
        title: "Unassigned Cases",
        isSearching: _isSearching,
        onSearchPressed: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _resetFilters();
            }
          });
        },
        onFilterPressed: () {
          showModalBottomSheet(
            backgroundColor: Colors.white,
            context: context,
            builder: (context) => _buildFilterOptions(),
          );
        },
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: const CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  )
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
                                    fetchCases();
                                  });
                                },
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.black,
                        onRefresh: () async {
                          setState(() {
                            fetchCases();
                          });
                        },
                        child: _filteredCases.isEmpty
                            ? const Center(child: Text('No cases found.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _filteredCases.length,
                                itemBuilder: (context, index) {
                                  final caseItem = _filteredCases[index];
                                  return CaseCard(
                                    caseItem: caseItem,
                                    isUnassigned: true,
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Filter Options",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                _updateFilteredCases();
              });
            },
            decoration: const InputDecoration(labelText: 'City'),
            items: [
              const DropdownMenuItem(
                value: 'All',
                child: Text('All Cities'),
              ),
              ..._cities.map(
                (city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCourt,
            onChanged: (value) {
              setState(() {
                _selectedCourt = value;
                _updateFilteredCases();
              });
            },
            decoration: const InputDecoration(labelText: 'Court'),
            items: [
              const DropdownMenuItem(
                value: 'All',
                child: Text('All Courts'),
              ),
              ..._courts.map(
                (court) => DropdownMenuItem(
                  value: court,
                  child: Text(court),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _resetFilters();
                  Navigator.pop(context);
                },
                child: const Text("Reset"),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
