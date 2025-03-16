import 'package:flutter/material.dart';

import '../../../models/proceed_history_list.dart';
import '../../../utils/dismissible_card.dart';

class ProceedHistoryItem extends StatelessWidget {
  final ProceedHistoryListData proceeding;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProceedHistoryItem({
    super.key,
    required this.proceeding,
    required this.onEdit,
    required this.onDelete,
  });

  String monthName(int month) {
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

  String formatDate(String date) {
    if (date.isEmpty || date == "0000-00-00") return "";
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.day} ${monthName(parsedDate.month)}, ${parsedDate.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black),
        ),
        child: DismissibleCard(
          name: 'proceeding data for "${proceeding.stage}" stage',
          onEdit: onEdit,
          onDelete: onDelete,
          child: Container(
            color: Color(0xFFF3F3F3),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                "Stage: ${proceeding.stage}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 2, color: Colors.black),
                  const SizedBox(height: 5),
                  Text("Inserted By: ${proceeding.insertedBy}"),
                  Divider(thickness: 1, color: Colors.black38),
                  Text(
                      "Added on: ${formatDate(proceeding.dateOfCreation.toString())}"),
                  Divider(thickness: 1, color: Colors.black38),
                  Text(
                      "Next Date: ${formatDate(proceeding.nextDate.toString())}"),
                  Divider(thickness: 1, color: Colors.black38),
                  Text("Next Stage: ${proceeding.nextStage}"),
                  Divider(thickness: 1, color: Colors.black38),
                  Text("Remark: ${proceeding.remark}"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
