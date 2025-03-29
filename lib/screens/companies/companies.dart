import 'dart:convert';

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/utils/dismissible_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import 'add_companies.dart';
import 'edit_company.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  CompaniesScreenState createState() => CompaniesScreenState();
}

class CompaniesScreenState extends State<CompaniesScreen> {
  List<Map<String, dynamic>> companies = [];
  bool isLoading = true;

  final String apiUrl = "$baseUrl/get_company_list";

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  Future<int> fetchCompanies([bool isOnPage = true]) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          companies = data
              .map((company) => {
                    'id': company['id'],
                    'company': '#${company['id']}',
                    'name': company['name'],
                    'contact_person': company['contact_person'],
                    'phone': company['contact_no'],
                    'status': company['status'],
                  })
              .toList();
          if (isOnPage) {
            setState(() {
              isLoading = false;
            });
          }
          return companies.length;
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load companies.');
      }
    } catch (error) {
      if (isOnPage) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
    return 0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteCompany(String companyId) async {
    try {
      final url = Uri.parse('$baseUrl/delete_company');
      final response = await http.post(url, body: {'company_id': companyId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            companies.removeWhere((company) => company['id'] == companyId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Company deleted successfully.")),
          );
        } else {
          _showError(data['response']);
        }
      } else {
        _showError("Failed to delete Company.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> company) async {
    print("Edit Company: ${company['id']}");
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCompanyScreen(
          companyId: company['id'],
          companyName: company['name'],
          contactPerson: company['contact_person'],
          contactNo: company['phone'],
          status: company['status'],
        ),
      ),
    );
    if (result) {
      fetchCompanies();
    }
  }

  void _handleDelete(String companyId) {
    print("Delete Company: $companyId");
    _deleteCompany(companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Companies',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        titleSpacing: -10,
        toolbarHeight: 70,
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leadingWidth: 56 + 10,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  )
                : LiquidPullToRefresh(
                    backgroundColor: Colors.black,
                    color: Colors.transparent,
                    showChildOpacityTransition: false,
                    onRefresh: fetchCompanies,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0), // Consistent padding
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        return DismissibleCard(
                          name: '${companies[index]['name']}',
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              // Softer corners
                              side: const BorderSide(
                                width: 1,
                                color: Colors.black,
                              ),
                            ),
                            elevation: 4, // Subtle shadow
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              // Consistent padding
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status Indicator
                                  Container(
                                    width: 8, // Slightly narrower
                                    decoration: BoxDecoration(
                                      color:
                                          companies[index]['status'] == 'enable'
                                              ? Colors.green
                                              : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text('\n\n\n\n\n'),
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 16), // Increased spacing
                                  // Details Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Company Name
                                        Text(
                                          '${companies[index]['name']}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 22, // Larger for emphasis
                                            fontWeight:
                                                FontWeight.w700, // Bolder
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Divider after name
                                        Divider(
                                          color: Colors.black54,
                                          thickness: 1,
                                          height: 1, // Tight spacing
                                        ),
                                        const SizedBox(height: 12),
                                        // Contact Person
                                        Text(
                                          'Contact Person: ${companies[index]['contact_person']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Contact Number
                                        Text(
                                          'Contact No.: +91 ${companies[index]['phone']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onEdit: () => {
                            print("Editing: ${companies[index]['id']}"),
                            _handleEdit(companies[index])
                          },
                          onDelete: () => _handleDelete(companies[index]['id']),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCompanyScreen(),
            ),
          );
          if (result == true) {
            fetchCompanies();
          }
        },
        backgroundColor: Colors.black,
        elevation: 4,
        // Add shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Softer corners
        ),
        label: const Text(
          'Add',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
