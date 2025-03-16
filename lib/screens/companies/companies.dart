import 'dart:convert';

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/utils/dismissible_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

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
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Companies',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        titleSpacing: -10,
        toolbarHeight: 70,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
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
                  ))
                : RefreshIndicator(
                    color: Colors.black,
                    onRefresh: fetchCompanies,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        return DismissibleCard(
                          name: '${companies[index]['name']}',
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: BorderSide(
                                width: 1,
                                color: Colors.black,
                              ),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 10,
                                    height: 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: companies[index]['status'] ==
                                                'enable'
                                            ? Colors.black
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                    height: 100,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${companies[index]['name']!}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Contact Person: ${companies[index]['contact_person']!}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Contact No.: +91 ${companies[index]['phone']!}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
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

          // Refresh the task list if a new task was added
          if (result == true) {
            fetchCompanies();
          }
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
