import 'dart:convert';

import 'package:case_sync/screens/interns/TaskInfoPage.dart';
import 'package:case_sync/screens/interns/add_tasks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../components/basicUIcomponent.dart';

class TasksPage extends StatefulWidget {
  final String caseId;
  final String caseNumber;

  const TasksPage({required this.caseId, Key? key, required this.caseNumber})
      : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  late Map<String, String> caseDetails = {};

  Future<void> fetchCaseInfo() async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_info');
      final response = await http.post(url, body: {'case_id': widget.caseId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print("Case Info API Response: $data");
        }
        if (data['success'] == true && data['data'].isNotEmpty) {
          setState(() {
            final caseData = data['data'][0];
            caseDetails = {
              'case_no': caseData['case_no'] ?? 'No data found',
              'year': caseData['year'] ?? 'No data found',
              'case_type': caseData['case_type'] ?? 'No data found',
              'Current Stage': caseData['stage_name'] ?? 'No data found',
              'Next Stage': caseData['next_stage'] ?? 'No data found',
              'applicant': caseData['applicant'] ?? 'No data found',
              'opponent': caseData['opp_name'] ?? 'No data found',
              'court': caseData['court_name'] ?? 'No data found',
              'location': caseData['city_name'] ?? 'No data found',
              'summonDate': caseData['sr_date'] ?? 'No data found',
              'assignedBy': 'Fetching...', // Placeholder
              'assignedTo': 'Fetching...', // Placeholder
              'nextDate': caseData['next_date'] ?? 'No data found',
              'remark': 'No remarks available.', // Placeholder
            };
          });
        } else {
          _showError("No data found for the given case.");
        }
      } else {
        _showError("Failed to fetch case details.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    print("######################################################33");
    print(caseDetails['case_type']);
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    fetchCaseInfo();
  }

  Future<void> _fetchTasks() async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_task');
      final request = http.MultipartRequest('POST', url);

      // Add the multipart data
      request.fields['case_no'] = widget.caseId;

      // Send the request and get the response
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          setState(() {
            _tasks = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          _showError(data['message'] ?? "No tasks found.");
        }
      } else {
        _showError("Failed to fetch tasks. Please try again.");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tasks",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : _tasks.isEmpty
              ? const Center(child: Text("No tasks found for this case."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            title: Text(
                              "Instruction: ${task['instruction']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Text("Alloted By: ${task['alloted_by']}"),
                                Text(
                                  "Alloted Date: ${_formatDate(task['alloted_date'])}",
                                ),
                                Text(
                                  "Expected End Date: ${_formatDate(task['expected_end_date'])}",
                                ),
                                Text("Status: ${task['status']}"),
                              ],
                            ),
                            onTap: () {
                              // Navigate to TaskInfoPage when the task is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TaskInfoPage(task: task),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      // Add the floating action button here
      floatingActionButton: ElevatedButton(
        style: AppTheme.elevatedButtonStyle, // Use the style from AppTheme
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(
                caseType: caseDetails['case_type'].toString(),
                caseNumber: widget.caseNumber,
                caseId: widget.caseId,
              ),
            ),
          );

          // Refresh the task list if a new task was added
          if (result == true) {
            _fetchTasks();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "Add Task",
              style: AppTheme
                  .buttonTextStyle, // Use the button text style from AppTheme
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty || date == "0000-00-00") return "";
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.day} ${_monthName(parsedDate.month)}, ${parsedDate.year}";
  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}
