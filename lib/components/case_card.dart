import 'package:case_sync/screens/cases/case_info/bottom_nav_bar.dart';
import 'package:case_sync/screens/interns/tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/case_list.dart';

class CaseCard extends StatelessWidget {
  final CaseListData caseItem;
  final bool isHighlighted;
  final bool isTask;
  final bool isUnassigned;
  final bool isOnCounter;

  const CaseCard({
    super.key,
    required this.caseItem,
    this.isHighlighted = false,
    this.isTask = false,
    this.isUnassigned = false,
    this.isOnCounter = false,
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
                : BottomNavBar(
                    caseId: caseItem.id,
                    caseNo: caseItem.caseNo,
                    isUnassigned: isUnassigned,
                    caseType: caseItem.caseType,
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
          side: BorderSide(color: Colors.black, style: BorderStyle.solid),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (isOnCounter) getIndicator(caseItem.caseCounter),
              if (isOnCounter) SizedBox(width: 10),
              Expanded(
                flex: 7,
                // Move Expanded here inside Row
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
                      '${caseItem.applicant.capitalize} vs ${caseItem.opponent.capitalize}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Summon Date: ${caseItem.srDate.day.toString().padLeft(2, '0')}/'
                      '${caseItem.srDate.month.toString().padLeft(2, '0')}/'
                      '${caseItem.srDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Court: ${caseItem.courtName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'City: ${caseItem.cityName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (caseItem.caseCounter.isEmpty)
                          ? "Case Counter: Not Available"
                          : "Case Counter: ${caseItem.caseCounter} days",
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getIndicator(String caseCounter) {
    return caseCounter.isEmpty
        ? SizedBox.shrink()
        : SizedBox(
            width: 10,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                  color: (int.parse(caseCounter) >= 30)
                      ? Colors.green
                      : (int.parse(caseCounter) >= 15)
                          ? Colors.yellow
                          : Colors.red,
                  borderRadius: BorderRadius.circular(16.0)),
            ),
          );
  }
}
