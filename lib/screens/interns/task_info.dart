import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TaskInfoPage extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskInfoPage({required this.task, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Task: ${task['instruction'] ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailsCard(
              title: 'Task Details',
              details: {
                'Case No.': task['case_num'] ?? '-',
                'Alloted By': task['alloted_by'] ?? '-',
                'Alloted To': task['alloted_to'] ?? '-',
                'Action By': task['action_by'] ?? '-',
                'Status': task['status'] ?? '-',
                'Remark': task['remark'] ?? '-',
                'Instruction': task['instruction'] ?? '-',
              },
            ),
            const SizedBox(height: 16),
            _buildDetailsCard(
              title: 'Task Dates',
              details: {
                'Alloted Date': _formatDate(task['alloted_date']),
                'Expected End Date': _formatDate(task['expected_end_date']),
              },
            ),
            const SizedBox(height: 16),
            // You can add more cards here as needed for additional information
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required Map<String, String> details,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...details.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty || date == "0000-00-00") return "No Date";
    final parsedDate = DateTime.tryParse(date);
    return parsedDate != null
        ? "${parsedDate.day} ${_monthName(parsedDate.month)}, ${parsedDate.year}"
        : "Invalid Date";
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
