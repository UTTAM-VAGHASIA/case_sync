import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/notification.dart';
import 'notification_card.dart';

class NotificationDrawer extends StatefulWidget {
  final List<Notifications> caseList;
  final Future<List<Notifications>> Function() onRefresh;
  const NotificationDrawer(
      {super.key, required this.caseList, required this.onRefresh});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  late List<Notifications> caseList;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    caseList = widget.caseList;
  }

  @override
  Widget build(BuildContext context) {
    void removeCase(Notifications caseItem) {
      setState(() {
        if (kDebugMode) {
          print("Removed: ${caseItem.msg}");
        }
        caseList.removeWhere((c) => c.id == caseItem.id);
      });
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Title Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Notifications Center',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(thickness: 1, height: 1, color: Colors.black54),

          // Notifications List or Empty State
          Expanded(
            child: caseList.isEmpty
                ? (isLoading)
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'No Cases with less than 10 days of counter',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Text(
                                'Long Press Here to Refresh 👇🏼',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              GestureDetector(
                                  onLongPress: () async {
                                    HapticFeedback.selectionClick();
                                    if (kDebugMode) {
                                      print("Long press detected");
                                    }
                                    setState(() {
                                      isLoading = true;
                                    });
                                    List<Notifications> tempList =
                                        await widget.onRefresh();
                                    setState(() {
                                      caseList = tempList;
                                      isLoading = false;
                                    });
                                  },
                                  child: Container(
                                    width: screenHeight * 0.3,
                                    height: screenHeight * 0.3,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(
                                          screenHeight * 0.3),
                                    ),
                                  ))
                            ],
                          ),
                        ),
                      )
                : RefreshIndicator(
                    color: Colors.black,
                    onRefresh: () async {
                      List<Notifications> tempList = await widget.onRefresh();
                      setState(() {
                        caseList = tempList;
                      });
                      if (kDebugMode) {
                        print("Refreshed: ${caseList.length}");
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: caseList.length,
                      itemBuilder: (context, index) {
                        return NotificationCard(
                          caseItem: caseList[index],
                          onDismiss: removeCase,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
