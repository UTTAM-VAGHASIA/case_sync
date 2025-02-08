import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting

import '../../utils/constants.dart';

class TaskInfoPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskInfoPage({required this.task, super.key});

  @override
  _TaskInfoPageState createState() => _TaskInfoPageState();
}

class _TaskInfoPageState extends State<TaskInfoPage> {
  bool _isCollapsed = true;
  bool _isRemarksCollapsed = true;
  String? errorMessage;
  bool isLoading = false;

  late List<Map<String, dynamic>> sampleTaskHistory = [];

  @override
  void initState() {
    super.initState();
    fetchRemarks();
  }

  Future<void> fetchRemarks() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse('$baseUrl/get_task_history');
      final response =
          await http.post(url, body: {'task_id': widget.task['id']});

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
    return widget.task.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
            color: Colors.black,
          ))
        : RefreshIndicator(
            color: Colors.black,
            onRefresh: fetchRemarks,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailsCard(details: widget.task),
                  const SizedBox(height: 16),
                  _buildRemarksCard(),
                ],
              ),
            ),
          );
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
                  Text(
                    'Remarks',
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
                  if (isLoading)
                    Center(
                      child: LinearProgressIndicator(
                        color: Colors.black,
                      ),
                    )
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
                            sampleTaskHistory[0]['remarks'],
                            style: TextStyle(
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
                          _buildKeyValueRow(
                              'Stage', sampleTaskHistory[0]['stage']),
                          _buildKeyValueRow('Date of Submission',
                              _formatDate(sampleTaskHistory[0]['dos'])),
                          _buildKeyValueRow('Date Time',
                              _formatDate(sampleTaskHistory[0]['date_time'])),
                          _buildKeyValueRow(
                              'Status', sampleTaskHistory[0]['status']),
                        ],
                      ),
                    )
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
                                style: TextStyle(
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
                              _buildKeyValueRow('Stage', entry['stage']),
                              _buildKeyValueRow('Date of Submission',
                                  _formatDate(entry['dos'])),
                              _buildKeyValueRow(
                                  'Date Time', _formatDate(entry['date_time'])),
                              _buildKeyValueRow('Status', entry['status']),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  if (!isLoading && errorMessage == null)
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
        details.entries.firstWhere((e) => e.key == 'case_num'),
        details.entries.firstWhere((e) => e.key == 'status'),
      ],
      'Assignment Details': [
        details.entries.firstWhere((e) => e.key == 'alloted_by'),
        details.entries.firstWhere((e) => e.key == 'alloted_to'),
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
                          _buildKeyValueRow('Case No.', details['case_num']),
                          _buildKeyValueRow(
                              'Alloted By', details['alloted_by']),
                          _buildKeyValueRow(
                              'Alloted To', details['alloted_to']),
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
