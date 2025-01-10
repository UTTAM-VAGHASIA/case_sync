import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http; // Add http for API calls
import 'package:intl/intl.dart'; // For date formatting

// CaseCard dependencies
import '../../components/case_card.dart';
import '../../models/case_list.dart';

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
      return DateFormat('d MMMM, yyyy').format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
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
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: interns.length,
                    itemBuilder: (context, index) {
                      final intern = interns[index];

                      // Show CaseCard for interns with case details
                      if (intern['has_case'] == true) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: CaseCard(
                            caseItem: CaseListData(
                              id: intern['case_id'] ?? '',
                              caseNo: intern['case_no'] ?? '',
                              applicant: intern['name'] ?? '',
                              opponent: intern['opponent'] ?? 'N/A',
                              srDate:
                                  DateTime.tryParse(intern['sr_date'] ?? '') ??
                                      DateTime.now(),
                              courtName: intern['court_name'] ?? 'N/A',
                              cityName: intern['city_name'] ?? 'N/A',
                              handleBy: intern['handle_by'] ?? 'N/A',
                            ),
                            isHighlighted: false, // Modify if needed
                          ),
                        );
                      }

                      // Default to InternCard for interns without case details
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InternCard(
                          id: intern['id'].toString(),
                          name: intern['name'],
                          contact: intern['contact'],
                          email: intern['email'],
                          dateTime: formatDate(intern['date_time']),
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
        side: const BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(10.0),
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
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '+91 $contact',
                  style: const TextStyle(
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  email, // Displaying email dynamically
                  style: const TextStyle(
                    fontSize: 14.0,
                  ),
                ),
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
