import 'dart:convert';
import 'package:case_sync/screens/cases/caseinfo.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../components/list_app_bar.dart';
import '../../models/case_list.dart'; // Import CaseListData model
import '../../components/case_card.dart'; // Import CaseCard widget

class UnassignedCases extends StatefulWidget {
  const UnassignedCases({Key? key}) : super(key: key);

  @override
  State<UnassignedCases> createState() => _UnassignedCasesState();
}

class _UnassignedCasesState extends State<UnassignedCases> {
  bool _isLoading = true;
  List<CaseListData> _unassignedCases = [];
  List<CaseListData> _filteredCases = [];
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
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_unassigned_case_list');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _unassignedCases = (data['data'] as List)
                .map((caseItem) => CaseListData(
                      id: caseItem['id']?.toString() ?? '',
                      caseNo: caseItem['case_no']?.toString() ?? '',
                      applicant: caseItem['applicant']?.toString() ?? 'N/A',
                      opponent: caseItem['opponent']?.toString() ?? 'N/A',
                      courtName: caseItem['court_name']?.toString() ?? 'N/A',
                      cityName: caseItem['city_name']?.toString() ?? 'N/A',
                      srDate: DateTime.parse(caseItem['sr_date']),
                      handleBy: '',
                    ))
                .toList();
            _filteredCases = List.from(_unassignedCases);

            _cities.addAll(
              _unassignedCases.map((caseItem) => caseItem.cityName).toSet(),
            );
            _courts.addAll(
              _unassignedCases.map((caseItem) => caseItem.courtName).toSet(),
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
                          return CaseCard(caseItem: caseItem);
                        },
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
                  _resetFilters();
                  Navigator.pop(context);
                },
                child: const Text("Reset"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Apply"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
