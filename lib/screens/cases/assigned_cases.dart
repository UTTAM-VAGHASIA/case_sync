import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../components/list_app_bar.dart';
import 'caseinfo.dart';

class AssignedCases extends StatefulWidget {
  const AssignedCases({Key? key}) : super(key: key);

  @override
  State<AssignedCases> createState() => _AssignedCasesState();
}

class _AssignedCasesState extends State<AssignedCases> {
  bool _isLoading = true;
  List<Map<String, String>> _assignedCases = [];
  List<Map<String, String>> _filteredCases = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedCity;
  String? _selectedCourt;
  final List<String> _cities = [];
  final List<String> _courts = [];

  @override
  void initState() {
    super.initState();
    _fetchCases();
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
                .map((caseItem) => {
                      "case_id": caseItem['id']?.toString() ?? '',
                      "case_no": caseItem['case_no']?.toString() ?? '',
                      "applicant": caseItem['applicant']?.toString() ?? 'N/A',
                      "court_name": caseItem['court_name']?.toString() ?? 'N/A',
                      "city_name": caseItem['city_name']?.toString() ?? 'N/A',
                    })
                .toList();
            _filteredCases = List.from(_assignedCases);

            _cities.addAll(
              _assignedCases.map((caseItem) => caseItem['city_name']!).toSet(),
            );
            _courts.addAll(
              _assignedCases.map((caseItem) => caseItem['court_name']!).toSet(),
            );
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
        final matchesSearchQuery = (caseItem['case_no'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (caseItem['applicant'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (caseItem['court_name'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (caseItem['city_name'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesCity = _selectedCity == null ||
            _selectedCity == 'All' ||
            caseItem['city_name'] == _selectedCity;
        final matchesCourt = _selectedCourt == null ||
            _selectedCourt == 'All' ||
            caseItem['court_name'] == _selectedCourt;

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
      _filteredCases = List.from(_assignedCases);
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Search by case number, applicant, court, or city',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
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
                  _resetFilters();
                  Navigator.pop(context); // Close the modal
                },
                child: const Text("Reset"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                },
                child: const Text("Apply"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(
        title: "Assigned Cases",
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
                ? const Center(child: CircularProgressIndicator())
                : _filteredCases.isEmpty
                    ? const Center(child: Text('No cases found.'))
                    : ListView.builder(
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
                                    caseId: caseItem['case_id'] ?? '',
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
                                      "Case No: ${caseItem['case_no'] ?? ''}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Applicant: ${caseItem['applicant'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Court: ${caseItem['court_name'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "City: ${caseItem['city_name'] ?? 'N/A'}",
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
