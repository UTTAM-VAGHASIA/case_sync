import 'dart:convert'; // For JSON decoding

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/screens/interns/adding%20forms/new_advocate.dart';
import 'package:case_sync/utils/dismissible_card.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import 'editing forms/edit_advocate.dart'; // Add http for API calls

class AdvocateListScreen extends StatefulWidget {
  const AdvocateListScreen({super.key});

  @override
  AdvocateListScreenState createState() => AdvocateListScreenState();
}

class AdvocateListScreenState extends State<AdvocateListScreen> {
  List<dynamic> advocates = []; // To store fetched advocates
  bool isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    fetchAdvocates(); // Fetch advocates on screen load
  }

  // Function to fetch data from the API
  Future<int> fetchAdvocates([bool isOnPage = true]) async {
    final String apiUrl =
        "$baseUrl/get_advocate_list"; // Corrected API endpoint
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          advocates = responseBody['data'];
          if (isOnPage) {
            setState(() {
              isLoading = false;
            });
          }
          print('Advocate List Length: ${advocates.length}');
          return advocates.length;
        } else {
          throw Exception(
              responseBody['message'] ?? 'Failed to load advocates');
        }
      } else {
        throw Exception('Failed to load advocates');
      }
    } catch (e) {
      if (isOnPage) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching advocates: $e");
    }
    return 0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteAdvocate(String advocateId) async {
    try {
      final url = Uri.parse('$baseUrl/delete_advocate');
      final response = await http.post(url, body: {'advocate_id': advocateId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            advocates.removeWhere((intern) => intern['id'] == advocateId);
          });
          SnackBarUtils.showSuccessSnackBar(context, "Advocate deleted successfully.");
        } else {
          _showError(data['response']);
        }
      } else {
        _showError("Failed to delete Advocate.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> advocate) async {
    print(advocate);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdvocateScreen(advocate: advocate),
      ),
    );
    if (result) {
      fetchAdvocates();
    }
  }

  void _handleDelete(String advocateId) {
    print("Delete Advocate: $advocateId");
    _deleteAdvocate(advocateId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3), // Set the background color
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 56 + 30,
        titleSpacing: -10,
        toolbarHeight: 70,
        title: Text(
          'Advocate List',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
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
      body: Container(
        color: const Color(0xFFF3F3F3), // Consistent background
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
                onRefresh: () => fetchAdvocates(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0), // Consistent padding
                  itemCount: advocates.length,
                  itemBuilder: (context, index) {
                    final advocate = advocates[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      // Space between cards
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.black, width: 1),
                          borderRadius:
                              BorderRadius.circular(12.0), // Softer corners
                        ),
                        elevation: 4,
                        // Subtle shadow
                        shadowColor: Colors.black.withOpacity(0.1),
                        child: DismissibleCard(
                          name: "${advocate['name']}",
                          onEdit: () => _handleEdit(advocate),
                          onDelete: () =>
                              _handleDelete(advocate['id'].toString()),
                          child: Padding(
                            padding: const EdgeInsets.all(
                                16.0), // Consistent padding
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Indicator
                                Container(
                                  width: 8, // Slightly narrower
                                  decoration: BoxDecoration(
                                    color: advocate['status'] == 'enable'
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text('\n\n\n\n\n'),
                                  ),
                                ),
                                const SizedBox(width: 16), // Increased spacing
                                // Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name
                                      Text(
                                        advocate['name'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 22, // Larger for emphasis
                                          fontWeight: FontWeight.w700, // Bolder
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
                                      // Contact
                                      Text(
                                        'Contact No.: +91 ${advocate['contact']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Email
                                      Text(
                                        'Email: ${advocate['email']}',
                                        style: const TextStyle(
                                          fontSize: 14,
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
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewAdvocateScreen(),
            ),
          );

          // Refresh the task list if a new task was added
          if (result) {
            fetchAdvocates();
          }
        },
        label: const Text('Add'),
        icon: SvgPicture.asset(
          'assets/icons/new_advocate.svg',
          color: Colors.white,
        ),
      ),
    );
  }
}
