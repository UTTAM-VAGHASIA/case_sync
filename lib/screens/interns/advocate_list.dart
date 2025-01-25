import 'dart:convert'; // For JSON decoding

import 'package:case_sync/screens/interns/adding%20forms/new_advocate.dart';
import 'package:case_sync/utils/dismissible_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'editing forms/edit_advocate.dart'; // Add http for API calls

class AdvocateListScreen extends StatefulWidget {
  const AdvocateListScreen({super.key});

  @override
  _AdvocateListScreenState createState() => _AdvocateListScreenState();
}

class _AdvocateListScreenState extends State<AdvocateListScreen> {
  List<dynamic> advocates = []; // To store fetched advocates
  bool isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    fetchAdvocates(); // Fetch advocates on screen load
  }

  // Function to fetch data from the API
  Future<void> fetchAdvocates() async {
    const String apiUrl =
        "https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_advocate_list"; // Corrected API endpoint
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          setState(() {
            advocates = responseBody['data'];
            isLoading = false;
          });
          print('Advocate List: $advocates');
        } else {
          throw Exception(
              responseBody['message'] ?? 'Failed to load advocates');
        }
      } else {
        throw Exception('Failed to load advocates');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching advocates: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteAdvocate(String advocateId) async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/delete_advocate');
      final response = await http.post(url, body: {'advocate_id': advocateId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            advocates.removeWhere((intern) => intern['id'] == advocateId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Advocate deleted successfully.")),
          );
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Advocate List',
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
                    itemCount: advocates.length,
                    itemBuilder: (context, index) {
                      final advocate = advocates[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(),
                        child: Card(
                          color: Colors.white, // Set card background to white
                          shape: RoundedRectangleBorder(
                            side:
                                const BorderSide(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 3, // Adds shadow effect
                          child: DismissibleCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                    height: 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: advocate['status'] == 'enable'
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
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          advocate['name'],
                                          style: const TextStyle(
                                            fontSize: 20.0,
                                          ),
                                        ),
                                        const SizedBox(height: 5.0),
                                        Text(
                                          'Contact No.: +91 ${advocate['contact']}',
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                          ),
                                        ),
                                        const SizedBox(height: 5.0),
                                        Text(
                                          'Email: ${advocate['email']}',
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                          ),
                                        ),
                                        const SizedBox(height: 5.0),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onEdit: () => _handleEdit(advocate),
                            onDelete: () =>
                                _handleDelete(advocate['id'].toString()),
                          ),
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
