import 'dart:convert';

import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../models/notification.dart';
import '../../services/shared_pref.dart';
import '../constants/constants.dart';
import 'notification_card.dart';

class NotificationDrawer extends StatefulWidget {
  final List<Notifications> caseList;
  final Future<List<Notifications>> Function() onRefresh;

  const NotificationDrawer({
    super.key,
    required this.caseList,
    required this.onRefresh,
  });

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  late List<Notifications> caseList;
  bool isLoading = false;
  DateTime? lastRefreshed;

  @override
  void initState() {
    super.initState();
    initialise();
    caseList = widget.caseList;
  }

  Future<void> initialise() async {
    lastRefreshed = await SharedPrefService.getLastRefreshed();
    setState(
        () {}); // Trigger rebuild to reflect the initial value of lastRefreshed
  }

  @override
  Widget build(BuildContext context) {
    void removeCase(Notifications caseItem) async {
      final String url = "$baseUrl/read_notification";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );
      request.fields['not_id'] = caseItem.id;

      try {
        final response = await request.send();

        if (response.statusCode == 200) {
          var ResponseData = await response.stream.bytesToString();
          final Map<String, dynamic> responseData = jsonDecode(ResponseData);
          if (responseData["success"] == true) {
            setState(() {
              caseList.removeWhere((c) => c.id == caseItem.id);
            });
            SnackBarUtils.showSuccessSnackBar(
              context,
              "Notification marked as read",
            );
          } else {
            SnackBarUtils.showErrorSnackBar(
              context,
              responseData['message'] ?? "Failed to mark notification as read",
            );
          }
        } else {
          SnackBarUtils.showErrorSnackBar(
            context,
            "Failed to call API. Status Code: ${response.statusCode}",
          );
        }
      } catch (e) {
        SnackBarUtils.showErrorSnackBar(
          context,
          "An error occurred while marking notification as read",
        );
      }
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
                                'No Notification (Last refreshed ${DateFormat.jm().format(lastRefreshed ?? DateTime.now())})',
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
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      isLoading = true;
                                    });
                                    await SharedPrefService.saveLastRefreshed(
                                        DateTime.now());
                                    List<Notifications> tempList =
                                        await widget.onRefresh();
                                    lastRefreshed = DateTime.now();
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
                : LiquidPullToRefresh(
                    backgroundColor: Colors.black,
                    color: Colors.transparent,
                    showChildOpacityTransition: false,
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      List<Notifications> tempList = await widget.onRefresh();
                      await SharedPrefService.saveLastRefreshed(DateTime.now());
                      lastRefreshed = DateTime.now();
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
