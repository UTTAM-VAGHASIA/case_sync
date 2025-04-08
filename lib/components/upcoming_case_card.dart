import 'dart:convert';

import 'package:case_sync/screens/cases/case_info/bottom_nav_bar.dart';
import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/case_list.dart';
import '../utils/priority_dialog.dart';

class UpcomingCaseCard extends StatefulWidget {
  final CaseListData caseItem;
  final bool isHighlighted;

  final Function(DateTime date) updateCases;

  const UpcomingCaseCard({
    super.key,
    required this.caseItem,
    required this.isHighlighted,
    required this.updateCases,
  });

  @override
  UpcomingCaseCardState createState() => UpcomingCaseCardState();
}

class UpcomingCaseCardState extends State<UpcomingCaseCard> {
  void _showPriorityDialog() {
    showDialog(
      context: context,
      builder: (context) => PriorityDialog(onPrioritySelected: updatePriority),
    );
    setState(() {});
  }

  Future<void> updatePriority(int? priority) async {
    final advocate = await SharedPrefService.getUser();
    final advocateId = advocate!.id;
    if (widget.caseItem.priorityNumber == null && priority != null) {
      // print("###################### ADDING ########################");
      await addPrioritySequence(widget.caseItem.id, priority, advocateId);
    } else if (widget.caseItem.priorityNumber != null && priority == null) {
      // print("###################### DELETING ########################");
      await deletePrioritySequence(widget.caseItem.priorityId);
    } else if (widget.caseItem.priorityNumber != null && priority != null) {
      // print("###################### UPDATING ########################");
      await updatePrioritySequence(
        widget.caseItem.id,
        widget.caseItem.priorityId,
        priority,
        advocateId,
      );
    }
  }

  Future<void> addPrioritySequence(
      String caseId, int sequence, String addedBy) async {
    try {
      // print("Case Id: $caseId");
      // print("Case Sequence: $sequence");
      // print("Added By: $addedBy");
      final url = Uri.parse("$baseUrl/add_sequence");
      final request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        'case_id': caseId,
        'sequence': sequence,
        'added_by': addedBy,
      });

      // print("Request Fields: \n ${request.fields['data']}");

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          // print("true");
          await widget.updateCases(widget.caseItem.nextDate);
        } else {
          // print("Failed");
        }
      }
    } catch (e) {
      // print("Catched");
      print(e);
    }
  }

  Future<void> deletePrioritySequence(String? sequenceId) async {
    try {
      final url = Uri.parse("$baseUrl/delete_sequence");
      final request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        'id': sequenceId,
      });

      // print("Request Fields: \n ${request.fields['data']}");

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        } else {
          // print("Failed");
        }
      }
    } catch (e) {
      // print("Catched");
      print(e);
    }
  }

  Future<void> updatePrioritySequence(
      String caseId, String? sequenceId, int sequence, String addedBy) async {
    try {
      final url = Uri.parse("$baseUrl/edit_sequence");
      final request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        'id': sequenceId,
        'case_id': caseId,
        'sequence': sequence,
        'added_by': addedBy,
      });

      // print("Request Fields: \n ${request.fields['data']}");

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        } else {
          // print("Failed");
        }
      }
    } catch (e) {
      // print("Catched");
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavBar(
              caseId: widget.caseItem.id,
              caseNo: widget.caseItem.caseNo,
              isUnassigned: true,
              caseType: widget.caseItem.caseType,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: widget.isHighlighted ? Colors.black : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black, style: BorderStyle.solid),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Case No: ${widget.caseItem.caseNo}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color:
                            widget.isHighlighted ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.fade,
                      maxLines: null,
                    ),
                  ),
                  (DateFormat("dd-MM-yyyy").format(widget.caseItem.nextDate) ==
                          DateFormat("dd-MM-yyyy").format(DateTime.now()))
                      ? (widget.caseItem.priorityNumber == null)
                          ? GestureDetector(
                              onTap: _showPriorityDialog,
                              child: Icon(
                                Icons.add_circle,
                                color: widget.isHighlighted
                                    ? Colors.white
                                    : Colors.black,
                                size: 32,
                              ),
                            )
                          : GestureDetector(
                              onTap: _showPriorityDialog,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isHighlighted
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${widget.caseItem.priorityNumber}',
                                  style: TextStyle(
                                    color: widget.isHighlighted
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                      : SizedBox.shrink()
                ],
              ),
              Divider(
                color: widget.isHighlighted ? Colors.white : Colors.black,
              ),
              Text(
                '${widget.caseItem.applicant.capitalize} vs ${widget.caseItem.opponent.capitalize}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Summon Date: ${widget.caseItem.srDate.day.toString().padLeft(2, '0')}/'
                '${widget.caseItem.srDate.month.toString().padLeft(2, '0')}/'
                '${widget.caseItem.srDate.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Court: ${widget.caseItem.courtName}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'City: ${widget.caseItem.cityName}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                (widget.caseItem.caseCounter.isEmpty ||
                        widget.caseItem.caseCounter == 'null')
                    ? "Case Counter: Not Available"
                    : "Case Counter: ${widget.caseItem.caseCounter} days",
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isHighlighted ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
