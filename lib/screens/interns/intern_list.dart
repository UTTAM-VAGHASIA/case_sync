import 'dart:convert'; // For JSON decoding

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/utils/dismissible_card.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http; // Add http for API calls
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import 'adding forms/new_intern.dart';
import 'editing forms/edit_intern.dart'; // For date formatting

class InternListScreen extends StatefulWidget {
  const InternListScreen({super.key});

  @override
  InternListScreenState createState() => InternListScreenState();
}

class InternListScreenState extends State<InternListScreen> {
  List<dynamic> interns = []; // To store fetched interns
  bool isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    fetchInterns(); // Fetch interns on screen load
  }

  // Function to fetch data from the API
  Future<int> fetchInterns([bool isOnPage = true]) async {
    final String apiUrl = "$baseUrl/get_interns_list";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print("Response Body: ${responseBody['data'].toString()}");
          interns = responseBody['data']; // Access the "data" key
          if (isOnPage) {
            setState(() {
              isLoading = false;
            });
          }
          return interns.length;
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to load interns');
        }
      } else {
        throw Exception('Failed to load interns');
      }
    } catch (e) {
      if (isOnPage) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching interns: $e");
    }
    return 0;
  }

  // Helper function to format date
  String formatDate(String dateTime) {
    if (dateTime == "0000-00-00" || dateTime.isEmpty) {
      return "No Date";
    }
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat("EEE, dd MMM, yyyy").format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  void _showError(String message) {
    SnackBarUtils.showErrorSnackBar(context, message);
  }

  Future<void> _deleteIntern(String internId) async {
    try {
      final url = Uri.parse('$baseUrl/delete_intern');
      final response = await http.post(url, body: {'intern_id': internId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            interns.removeWhere((intern) => intern['id'] == internId);
          });
          SnackBarUtils.showSuccessSnackBar(context, "Intern deleted successfully.");
        } else {
          _showError(data['response']);
        }
      } else {
        _showError("Failed to delete Intern.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> intern) async {
    print(intern);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInternScreen(intern: intern),
      ),
    );
    fetchInterns();
  }

  void _handleDelete(String internId) {
    print("Delete Intern: $internId");
    _deleteIntern(internId);
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
          'Intern List',
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
        color: const Color(0xFFF3F3F3), // Match AddTaskScreen background
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
                onRefresh: fetchInterns,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0), // Consistent padding
                  itemCount: interns.length,
                  itemBuilder: (context, index) {
                    final intern = interns[index];

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
                        // Subtle shadow for depth
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        child: DismissibleCard(
                          name: '${intern['name']}',
                          onEdit: () => _handleEdit(intern),
                          onDelete: () =>
                              _handleDelete(intern['id'].toString()),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            // Consistent inner padding
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Indicator
                                Container(
                                  width: 8, // Slightly narrower
                                  decoration: BoxDecoration(
                                    color: intern['status'] == 'enable'
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
                                        intern['name'],
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
                                        height: 1, // Tighten spacing
                                      ),
                                      const SizedBox(height: 12),
                                      // Contact
                                      Text(
                                        'Contact No.: +91 ${intern['contact']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Email
                                      Text(
                                        'Email: ${intern['email']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Joining Date
                                      Text(
                                        'Joining Date: ${formatDate(intern['date_time'])}',
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
              builder: (context) => NewInternScreen(),
            ),
          );

          // Refresh the task list if a new task was added
          if (result == true) {
            fetchInterns();
          }
        },
        label: const Text('Add'),
        icon: SvgPicture.asset(
          'assets/icons/new_intern.svg',
          color: Colors.white,
        ),
      ),
    );
  }
}
