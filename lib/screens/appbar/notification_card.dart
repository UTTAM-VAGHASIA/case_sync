import 'package:case_sync/screens/interns/tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/case.dart';
import '../cases/case_info.dart';

class NotificationCard extends StatelessWidget {
  final Case caseItem;
  final bool isHighlighted;
  final bool isTask;
  final Function(Case) onDismiss; // Callback when dismissed

  const NotificationCard({
    super.key,
    required this.caseItem,
    required this.onDismiss, // Required function for dismissal
    this.isHighlighted = false,
    this.isTask = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isTask
                ? TasksPage(
                    caseId: caseItem.id,
                    caseNumber: caseItem.caseNo,
                  )
                : CaseInfoPage(
                    caseId: caseItem.id,
                    caseNo: caseItem.caseNo,
                  ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, style: BorderStyle.solid),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Dismissible(
            key: Key(caseItem.id.toString()), // Unique key for each item
            direction: DismissDirection.endToStart, // Swipe left to dismiss
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.centerRight,
              child: const Icon(
                Icons.mark_chat_read_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            onDismissed: (direction) {
              HapticFeedback.lightImpact();
              onDismiss(caseItem); // Notify parent to remove item
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Case No: ${caseItem.caseNo}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: isHighlighted ? Colors.white : Colors.black,
                    ),
                  ),
                  Divider(
                    color: isHighlighted ? Colors.white : Colors.black,
                  ),
                  Text(
                    'Case Counter: ${caseItem.caseCounter} days',
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighlighted ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
