import 'package:flutter/material.dart';

import '../../models/case.dart';
import 'notification_card.dart';

class NotificationDrawer extends StatefulWidget {
  final List<Case> caseList;
  const NotificationDrawer({super.key, required this.caseList});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(201, 201, 201, 1.0),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: (widget.caseList.isEmpty)
          ? Center(
              child: Text(
                'No Cases with less than 10 days of counter',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.caseList.length,
              itemBuilder: (context, index) {
                return NotificationCard(
                  caseItem: widget.caseList[index],
                );
              },
            ),
    );
  }
}
