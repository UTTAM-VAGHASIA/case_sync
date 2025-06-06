import 'dart:convert';

import 'package:case_sync/screens/interns/reassign_task.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:case_sync/utils/slideable_card.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../../components/basic_ui_component.dart';
import '../../constants/constants.dart';
import '../../interns/adding forms/add_tasks.dart';
import '../../interns/editing forms/edit_task.dart';
import '../../interns/task_info.dart';

class TaskHistoryPage extends StatefulWidget {
  final String caseId;
  final String caseNo;

  final String caseType;

  const TaskHistoryPage({
    super.key,
    required this.caseId,
    required this.caseNo,
    required this.caseType,
  });

  @override
  State<TaskHistoryPage> createState() => TaskHistoryPageState();
}

class TaskHistoryPageState extends State<TaskHistoryPage>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  String? advocateId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final advocate = await SharedPrefService.getUser();
    advocateId = advocate!.id;
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
            print('Task Details: ${_tasks[0]}');
          });
        } else {
          if (mounted) {
            _showError(data['message'] ?? "No tasks found.", context);
          }
          setState(() {
            _tasks = [];
          });
        }
      } else {
        if (mounted) {
          _showError("Failed to fetch tasks. Please try again.", context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError("An error occurred: $e", context);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReassign(task) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      // isScrollControlled allows the sheet to take up more height,
      // especially needed when the keyboard appears.
      isScrollControlled: true,
      // Make corners rounded to match typical modal style
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Prevent dismissal by tapping outside if an operation is in progress? (optional)
      // isDismissible: !_isLoading, // You'd need to pass _isLoading state or manage it differently
      backgroundColor: Colors.white,
      // Or your desired sheet background color
      builder: (BuildContext sheetContext) {
        // Pass the necessary IDs to the sheet widget
        return ReAssignTaskSheet(
          taskId: task['id'],
          advocateId: advocateId!,
        );
      },
    );

    // Optional: Handle the result after the sheet is closed
    if (result == true) {
      // Reassignment was successful (sheet popped with 'true')
      print('Task reassignment successful. Refreshing list...');
      fetchTasks();
      // e.g., call a method passed down via constructor or use a state management solution
    } else {
      // Sheet was dismissed without success (e.g., back button, tapped outside)
      print('Reassign task sheet closed without completing.');
    }
  }

  void _showError(String message, BuildContext cont) {
    SnackBarUtils.showErrorSnackBar(cont, message);
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final url = Uri.parse('$baseUrl/delete_task');
      final response = await http.post(url, body: {'task_id': taskId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _tasks.removeWhere((task) => task['id'] == taskId);
          });
          if (mounted) {
            SnackBarUtils.showSuccessSnackBar(
                context, "Task deleted successfully.");
          }
        } else {
          if (mounted) {
            _showError(data['message'] ?? "Failed to delete task.", context);
          }
        }
      } else {
        if (mounted) {
          _showError("Failed to delete task.", context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError("An error occurred: $e", context);
      }
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> task) async {
    print("Edit task: ${task['instruction']}");
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
    print("Delete task: ${task['instruction']}");
    _deleteTask(task['id']);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: Colors.black,
                width: 1,
              )),
          elevation: 3,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                  color: Colors.black,
                ))
              : _tasks.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(child: Text("No tasks found for this case.")),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            fetchTasks();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LiquidPullToRefresh(
                        backgroundColor: Colors.black,
                        color: Colors.transparent,
                        showChildOpacityTransition: false,
                        onRefresh: () async {
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
                                child: SlideableCard(
                                  name: 'this task',
                                  onEdit: () => _handleEdit(task),
                                  onDelete: () => _handleDelete(task),
                                  canReassign: true,
                                  // (task['alloted_to_id'] == advocateId),
                                  onReassign: () => _handleReassign(task),
                                  child: Container(
                                    color: Color(0xFFF3F3F3),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      title: Text(
                                        "Instruction: ${task['instruction']}",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Divider(
                                            thickness: 2,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                              "Alloted By: ${task['alloted_by']}"),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black38,
                                          ),
                                          Text(
                                              "Alloted To: ${task['alloted_to']}"),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black38,
                                          ),
                                          Text(
                                            "Alloted Date: ${_formatDate(task['alloted_date'])}",
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black38,
                                          ),
                                          Text(
                                            "Expected End Date: ${_formatDate(task['expected_end_date'])}",
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black38,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text("Status: "),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: getColor(
                                                        task['status']),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                                child: Text(
                                                  task['status'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        HapticFeedback.mediumImpact();
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TaskInfoPage(
                                                taskId: task['id']),
                                          ),
                                        );
                                        fetchTasks();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                caseType: widget.caseType,
                caseNumber: widget.caseNo,
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

Color getColor(task) {
  if (task.toLowerCase().contains("pending")) {
    return Color(0xFFFFC107);
  } else if (task.toLowerCase().contains("allotted") ||
      task.toLowerCase().contains('alloted')) {
    return Color(0XFF0D6EFD);
  } else if (task.toLowerCase().contains("reassign")) {
    return Color(0XFF0DCAF0);
  } else if (task.toLowerCase().contains("completed")) {
    return Color(0XFF198754);
  } else if (task.toLowerCase().contains("re-allotted") ||
      task.toLowerCase().contains("re-alloted")) {
    return Color(0XFFDC3545);
  } else {
    return Color(0XFFDC3545);
  }
}
