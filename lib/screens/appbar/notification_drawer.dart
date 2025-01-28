import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/case.dart';
import '../../utils/constants.dart';
import 'notification_card.dart';

class NotificationDrawer extends StatefulWidget {
  const NotificationDrawer({super.key});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  bool isLoading = true;
  String errorMessage = '';
  List<Case> caseList = [];

  @override
  void initState() {
    super.initState();
    fetchCaseCounter();
  }

  Future<void> fetchCaseCounter() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/get_case_counter'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(responseData['data']);
        print('Error Message before: $errorMessage');
        if (responseData['success']) {
          print('Entered If');
          setState(() {
            print('error message: $errorMessage');
            caseList = (responseData['data'] as List)
                .map((caseItem) => Case.fromJson(caseItem))
                .toList();
            print(caseList);
            errorMessage = '';
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Unknown error';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to fetch data. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
    print(errorMessage);
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
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            )
          : (errorMessage.isNotEmpty)
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: caseList.length,
                  itemBuilder: (context, index) {
                    return NotificationCard(
                      caseItem: caseList[index],
                    );
                  },
                ),
    );
  }
}
