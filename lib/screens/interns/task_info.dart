import 'dart:convert';

import 'package:case_sync/screens/interns/adding%20forms/add_remark.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../components/basic_ui_component.dart';
import '../constants/constants.dart';

class TaskInfoPage extends StatefulWidget {
  final String taskId;

  const TaskInfoPage({required this.taskId, super.key});

  @override
  _TaskInfoPageState createState() => _TaskInfoPageState();
}

class _TaskInfoPageState extends State<TaskInfoPage> {
  bool _isCollapsed = false;
  bool _isRemarksCollapsed = true;
  String? errorMessage;
  bool isLoading = false;
  List<Map<String, dynamic>> stageList = [];

  Map<String, dynamic> task = {};
  late List<Map<String, dynamic>> sampleTaskHistory = [];

  @override
  void initState() {
    super.initState();
    print(widget.taskId);
    fetchTaskDetails();
    fetchRemarks();
  }

  Future<void> _fetchStageList() async {
    try {
      if (kDebugMode) {
        print("Fetching stage list...");
      }
      final url = Uri.parse('$baseUrl/stage_list');
      var request = http.MultipartRequest("POST", url);
      request.fields['case_id'] = task['case_id'];

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['success'] == true) {
        setState(() {
          stageList = List<Map<String, dynamic>>.from(data['data']);
          if (kDebugMode) {
            print("Stage List: $stageList");
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching stage list: $e");
      }
    }
    if (kDebugMode) {
      print("Fetched stage list");
    }
  }

  Future<void> fetchTaskDetails() async {
    setState(() {
      isLoading = true;
    });
    try {
      print("Fetching Task: ");
      final url = Uri.parse('$baseUrl/get_task_info');
      final response = await http.post(url, body: {'task_id': widget.taskId});
      print("Response Received: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("${data['data']}");
        if (data['data'] is List && data['data'].isNotEmpty) {
          setState(() {
            task =
                Map<String, dynamic>.from(data['data'][0]); // Safe conversion
            if (kDebugMode) {
              print("Task fetched: $task");
            }
            errorMessage = null;
            isLoading = false;
          });
          _fetchStageList();
        } else {
          setState(() {
            errorMessage = "No task found for the given ID.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to fetch task details.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        isLoading = false;
      });
    }
  }

  Future<void> fetchRemarks() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse('$baseUrl/get_task_history');
      final response = await http.post(url, body: {'task_id': widget.taskId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'].isNotEmpty) {
          setState(() {
            sampleTaskHistory = List<Map<String, dynamic>>.from(data['data']);
            errorMessage = null;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "No remarks found for the given task.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to fetch remarks.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
      backgroundColor: Color(0xFFF3F3F3),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFFF3F3F3),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/back_arrow.svg',
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'Task Details',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return task.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
            color: Colors.black,
          ))
        : LiquidPullToRefresh(
            backgroundColor: Colors.black,
            color: Colors.transparent,
            showChildOpacityTransition: false,
            onRefresh: () async {
              fetchTaskDetails();
              fetchRemarks();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailsCard(details: task),
                  const SizedBox(height: 16),
                  _buildRemarksCard(),
                ],
              ),
            ),
          );
  }

  Future<void> _showUpdateStageModal() async {
    // Pass stage ID, not name
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddRemarkModal(
          currentStage: task['stage'],
          taskId: task['id'],
          caseId: task['case_id'],
          stageId: task['stage'],
        );
      },
    );

    fetchRemarks();
  }

  Widget _buildRemarksCard() {
    return GestureDetector(
      onTap: () {
        if (sampleTaskHistory.isNotEmpty &&
            !isLoading &&
            errorMessage == null) {
          setState(() {
            _isRemarksCollapsed = !_isRemarksCollapsed;
          });
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
            color: Colors.black,
            width: 1,
          ),
        ),
        elevation: 3,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remarks',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      ElevatedButton(
                        style: AppTheme.elevatedButtonStyle.copyWith(
                            shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)))),
                        // Use the style from AppTheme
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          _showUpdateStageModal();
                        },
                        child: Text(
                          "Add Remark",
                          style: AppTheme.buttonTextStyle.apply(
                              fontSizeDelta:
                                  0.1), // Use the button text style from AppTheme
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    thickness: 2,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 8),

                  // Show loading indicator
                  if (isLoading)
                    const Center(
                      child: LinearProgressIndicator(
                        color: Colors.black,
                      ),
                    )

                  // Show error message
                  else if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.red,
                        ),
                      ),
                    )

                  // Show empty remarks message
                  else if (sampleTaskHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "No remarks available.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    )

                  // Show remarks when collapsed
                  else if (_isRemarksCollapsed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sampleTaskHistory.first['remarks'],
                            // Safe access
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const Divider(thickness: 2, color: Colors.black),
                          const SizedBox(height: 8),
                          _buildKeyValueRow(
                              'Stage', sampleTaskHistory.first['stage_name']),
                          _buildKeyValueRow('Date of Submission',
                              _formatDate(sampleTaskHistory.first['fdos'])),
                          _buildKeyValueRow('Date Time',
                              _formatDate(sampleTaskHistory.first['fdt'])),
                          _buildKeyValueRow(
                              'Status', sampleTaskHistory.first['status']),
                        ],
                      ),
                    )

                  // Show full remarks list when expanded
                  else
                    Column(
                      children: sampleTaskHistory.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['remarks'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const Divider(thickness: 2, color: Colors.black),
                              const SizedBox(height: 8),
                              _buildKeyValueRow('Stage', entry['stage_name']),
                              _buildKeyValueRow('Date of Submission',
                                  _formatDate(entry['fdos'])),
                              _buildKeyValueRow(
                                  'Date Time', _formatDate(entry['fdt'])),
                              _buildKeyValueRow('Status', entry['status']),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  if (!isLoading &&
                      errorMessage == null &&
                      sampleTaskHistory.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _isRemarksCollapsed
                              ? "See more Remarks"
                              : "See less Remarks",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard({required Map<String, dynamic> details}) {
    final Map<String, List<MapEntry<String, dynamic>>> groupedDetails = {
      'General Info': [
        details.entries.firstWhere((e) => e.key == 'case_no'),
        details.entries.firstWhere((e) => e.key == 'status'),
      ],
      'Assignment Details': [
        details.entries.firstWhere((e) => e.key == 'alloted_by_name'),
        details.entries.firstWhere((e) => e.key == 'alloted_to_name'),
        details.entries.firstWhere((e) => e.key == 'action_by'),
      ],
      'Dates': [
        details.entries.firstWhere((e) => e.key == 'alloted_date'),
        details.entries.firstWhere((e) => e.key == 'expected_end_date'),
      ],
      'Instruction': [
        details.entries.firstWhere((e) => e.key == 'instruction'),
      ],
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(
          color: Colors.black,
          width: 1,
        ),
      ),
      elevation: 3,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
            child: Container(
              padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isCollapsed)
                    // Display the specified fields when collapsed
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildKeyValueRow('Case No.', details['case_no']),
                          _buildKeyValueRow(
                              'Alloted By', details['alloted_by_name']),
                          _buildKeyValueRow(
                              'Alloted To', details['alloted_to_name']),
                          _buildKeyValueRow('Alloted Date',
                              _formatDate(details['alloted_date'])),
                          _buildKeyValueRow('Expected End Date',
                              _formatDate(details['expected_end_date'])),
                          ...groupedDetails.entries.map((section) {
                            if (section.key != 'Instruction') {
                              return SizedBox.shrink();
                            }

                            return Container(
                              // margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section Header
                                  Text(
                                    section.key,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 2,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    section.value.first.value?.toString() ??
                                        '-',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(
                            height: 12,
                          ),
                        ],
                      ),
                    )
                  else
                    // Display all details when expanded
                    ...groupedDetails.entries.map((section) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header
                            Text(
                              section.key,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const Divider(
                              thickness: 2,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 8),
                            if (section.key == 'Instruction')
                              Text(
                                section.value.first.value?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              )
                            else
                              ...section.value.map((entry) {
                                String displayValue;

                                // Handle date formatting
                                if (['alloted_date', 'expected_end_date']
                                    .contains(entry.key)) {
                                  displayValue = _formatDate(entry.value);
                                } else if (entry.value == null ||
                                    entry.value.toString().isEmpty ||
                                    entry.value == '0000-00-00') {
                                  displayValue = '-';
                                } else {
                                  displayValue = entry.value.toString();
                                }

                                // Convert the key to a more readable format if needed
                                String displayKey = _formatKey(entry.key);

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            displayKey,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            displayValue,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (section.value.last != entry)
                                      const Divider(
                                        thickness: 1,
                                        color: Colors.black38,
                                      ),
                                  ],
                                );
                              }),
                          ],
                        ),
                      );
                    }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isCollapsed ? "Click to Expand" : "Click to Collapse",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String key, dynamic value) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value?.toString() ?? '-',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        if (!(key == "Status"))
          const Divider(
            thickness: 1,
            color: Colors.black38,
          ),
      ],
    );
  }

  // Helper methods for formatting keys and dates
  String _formatKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty || date == '0000-00-00') {
      return 'No Date';
    }
    try {
      DateTime parsedDate;
      if (date is DateTime) {
        parsedDate = date;
      } else {
        parsedDate = DateTime.parse(date.toString());
      }
      return DateFormat('EEE, MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
