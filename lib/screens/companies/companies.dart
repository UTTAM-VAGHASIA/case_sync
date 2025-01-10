import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import '../appbar/settings_drawer.dart';
import 'add_companies.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  CompaniesScreenState createState() => CompaniesScreenState();
}

class CompaniesScreenState extends State<CompaniesScreen> {
  List<Map<String, dynamic>> companies = [];
  bool isLoading = true;

  // API URL
  final String apiUrl =
      "https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_company_list";

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Transform API data into a usable list format
          final List<dynamic> data = responseData['data'];
          setState(() {
            companies = data
                .map((company) => {
                      'company': '#${company['id']}',
                      'name': company['name'],
                      'contact_person': company['contact_person'],
                      'phone': company['contact_no'],
                    })
                .toList();
            isLoading = false;
          });
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load companies.');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 56 + 30,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Title below the AppBar
          Container(
            color: const Color(0xFFF3F3F3),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Companies',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      companies[index]['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(companies[index]['contact_person']!),
                                    Text(companies[index]['phone']!),
                                  ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCompanyScreen()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.black,
      ),
    );
  }
}
