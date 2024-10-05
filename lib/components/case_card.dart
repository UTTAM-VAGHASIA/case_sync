import 'package:flutter/material.dart';

class CaseCard extends StatelessWidget {
  final String caseId;
  final String plaintiff;
  final String location;
  final bool isHighlighted;

  const CaseCard({super.key, 
    required this.caseId,
    required this.plaintiff,
    required this.location,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isHighlighted ? Colors.black : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caseId,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : Colors.black,
              ),
            ),
            Text(
              plaintiff,
              style: TextStyle(
                color: isHighlighted ? Colors.white : Colors.black,
              ),
            ),
            Text(
              location,
              style: TextStyle(
                color: isHighlighted ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
