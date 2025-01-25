import 'dart:convert'; // For JSON decoding

import 'package:case_sync/utils/dismissible_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http; // Add http for API calls
import 'package:intl/intl.dart';

import '../officials/new_intern.dart'; // For date formatting

class InternListScreen extends StatefulWidget {
  const InternListScreen({super.key});

  @override
  _InternListScreenState createState() => _InternListScreenState();
}

class _InternListScreenState extends State<InternListScreen> {
  List<dynamic> interns = []; // To store fetched interns
  bool isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    fetchInterns(); // Fetch interns on screen load
  }

  // Function to fetch data from the API
  Future<void> fetchInterns() async {
    const String apiUrl =
        "https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_interns_list";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          setState(() {
            interns = responseBody['data']; // Access the "data" key
            isLoading = false;
          });
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to load interns');
        }
      } else {
        throw Exception('Failed to load interns');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching interns: $e");
    }
  }

  // Helper function to format date
  String formatDate(String dateTime) {
    if (dateTime == "0000-00-00" || dateTime.isEmpty) {
      return "No Date";
    }
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteIntern(String internId) async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/delete_intern');
      final response = await http.post(url, body: {'intern_id': internId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            interns.removeWhere((intern) => intern['id'] == internId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Intern deleted successfully.")),
          );
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

  void _handleEdit(String internId) {
    print("Edit Intern: $internId");
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
          Container(
            color: const Color(0xFFF3F3F3),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Intern List',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                    color: Colors.black,
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: interns.length,
                    itemBuilder: (context, index) {
                      final intern = interns[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(),
                        child: DismissibleCard(
                          child: InternCard(
                            id: intern['id'].toString(),
                            name: intern['name'],
                            contact: intern['contact'],
                            email: intern['email'],
                            dateTime: formatDate(intern['date_time']),
                          ),
                          onEdit: () => _handleEdit(intern['id'].toString()),
                          onDelete: () =>
                              _handleDelete(intern['id'].toString()),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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

class InternCard extends StatelessWidget {
  final String id;
  final String name;
  final String contact;
  final String email;
  final String dateTime;

  const InternCard({
    super.key,
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // Set card background to white
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 3, // Adds shadow effect
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section: ID, name, and placeholder details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  'Contact No.: +91 $contact',
                  style: const TextStyle(
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  'Email: $email', // Displaying email dynamically
                  style: const TextStyle(
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 5.0),
              ],
            ),
            // Right section: date_time
            Text(
              dateTime,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
