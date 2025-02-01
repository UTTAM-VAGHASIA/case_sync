import 'package:case_sync/screens/interns/tasks.dart';
import 'package:flutter/material.dart';

import '../../models/case.dart';
import '../cases/case_info.dart';

class NotificationCard extends StatelessWidget {
  final Case caseItem;
  final bool isHighlighted;
  final bool isTask;

  const NotificationCard({
    super.key,
    required this.caseItem,
    this.isHighlighted = false,
    this.isTask = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
        margin: const EdgeInsets.symmetric(
          vertical: 8.0,
        ),
        color: isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black, style: BorderStyle.solid)),
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
    );
  }
}
