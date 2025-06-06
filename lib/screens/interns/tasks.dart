import 'dart:convert';

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/screens/interns/adding%20forms/add_tasks.dart';
import 'package:case_sync/screens/interns/editing%20forms/edit_task.dart';
import 'package:case_sync/screens/interns/task_info.dart';
import 'package:case_sync/utils/dismissible_card.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../components/basic_ui_component.dart';

class TasksPage extends StatefulWidget {
  final String caseId;
  final String caseNumber;

  const TasksPage({required this.caseId, super.key, required this.caseNumber});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  late Map<String, String> caseDetails = {};

  Future<void> _fetchCaseInfo() async {
    try {
      final url = Uri.parse('$baseUrl/get_case_info');
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
  }

  @override
  void initState() {
    super.initState();
    fetchTasks();
    _fetchCaseInfo();
  }

  Future<void> fetchTasks() async {
    try {
      final url = Uri.parse('$baseUrl/get_case_task');
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
            if (kDebugMode) {
              print('Task Details: ${_tasks[0]}');
            }
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

  Future<void> _deleteTask(String taskId) async {
    var scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final url = Uri.parse('$baseUrl/delete_task');
      final response = await http.post(url, body: {'task_id': taskId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _tasks.removeWhere((task) => task['id'] == taskId);
          });
          SnackBarUtils.showSuccessSnackBar(context, "Task deleted successfully.");
        } else {
          _showError(data['message'] ?? "Failed to delete task.");
        }
      } else {
        _showError("Failed to delete task.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    SnackBarUtils.showErrorSnackBar(context, message);
  }

  Future<void> _handleEdit(Map<String, dynamic> task) async {
    if (kDebugMode) {
      print("Edit task: ${task['instruction']}");
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(taskDetails: task),
      ),
    );
    if (result) {
      fetchTasks();
    }
  }

  void _handleDelete(Map<String, dynamic> task) {
    if (kDebugMode) {
      print("Delete task: ${task['instruction']}");
    }
    _deleteTask(task['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Tasks for Case: ${widget.caseNumber}",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            )
          : _tasks.isEmpty
              ? const Center(child: Text("No tasks found for this case."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LiquidPullToRefresh(
                    backgroundColor: Colors.black,
                    color: Colors.transparent,
                    showChildOpacityTransition: false,
                    onRefresh: () async {
                      _fetchCaseInfo();
                      fetchTasks();
                    },
                    child: ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black),
                            ),
                            child: DismissibleCard(
                              name: 'this task',
                              child: Container(
                                color: Colors.white,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  title: Text(
                                    "Instruction: ${task['instruction']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text("Alloted By: ${task['alloted_by']}"),
                                      Text("Alloted To: ${task['alloted_to']}"),
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
                                    HapticFeedback.mediumImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TaskInfoPage(taskId: task['id']),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              onEdit: () => _handleEdit(task),
                              onDelete: () => _handleDelete(task),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
      floatingActionButton: ElevatedButton(
        style: AppTheme.elevatedButtonStyle, // Use the style from AppTheme
        onPressed: () async {
          HapticFeedback.mediumImpact();
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
            fetchTasks();
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
    return months[month - 1];
  }
}
