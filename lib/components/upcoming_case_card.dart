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
      builder: (context) => PriorityDialog(
        onPrioritySelected: updatePriority,
        initialPriority: widget.caseItem.priorityNumber?.toString(),
        initialRemark: widget.caseItem.remark,
      ),
    );
    setState(() {});
  }

  Future<void> updatePriority(int? priority, String? remark) async {
    final advocate = await SharedPrefService.getUser();
    final advocateId = advocate!.id;
    if (widget.caseItem.priorityNumber == null && priority != null) {
      await addPrioritySequence(
        widget.caseItem.id,
        priority,
        advocateId,
        remark,
      );
    } else if (widget.caseItem.priorityNumber != null && priority == null) {
      await deletePrioritySequence(widget.caseItem.priorityId);
    } else if (widget.caseItem.priorityNumber != null && priority != null) {
      await updatePrioritySequence(
        widget.caseItem.id,
        widget.caseItem.priorityId,
        priority,
        advocateId,
        remark,
      );
    }
  }

  // API methods remain unchanged
  Future<void> addPrioritySequence(
      String caseId, int sequence, String addedBy, String? remark) async {
    // Implementation unchanged
    try {
      final url = Uri.parse("$baseUrl/add_sequence");
      final request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        'case_id': caseId,
        'sequence': sequence,
        'added_by': addedBy,
        'remark': remark,
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> deletePrioritySequence(String? sequenceId) async {
    // Implementation unchanged
    try {
      final url = Uri.parse("$baseUrl/delete_sequence");
      final request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        'id': sequenceId,
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updatePrioritySequence(String caseId, String? sequenceId,
      int sequence, String addedBy, String? remark) async {
    // Implementation unchanged
    try {
      final url = Uri.parse("$baseUrl/edit_sequence");
      final request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        'id': sequenceId,
        'case_id': caseId,
        'sequence': sequence,
        'added_by': addedBy,
        'remark': remark,
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          await widget.updateCases(widget.caseItem.nextDate);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  bool get _isToday {
    return DateFormat("dd-MM-yyyy").format(widget.caseItem.nextDate) ==
        DateFormat("dd-MM-yyyy").format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isHighlighted ? Colors.black : Colors.white;
    final textColor = widget.isHighlighted ? Colors.white : Colors.black;
    final accentColor =
        widget.isHighlighted ? Colors.white.withOpacity(0.7) : Colors.black54;

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
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.isHighlighted
                ? Colors.white
                : Colors.black,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with case number and priority
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              decoration: BoxDecoration(
                color: widget.isHighlighted
                    ? Colors.grey.shade900
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Case No: ${widget.caseItem.caseNo}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: textColor,
                      ),
                      maxLines: null,
                    ),
                  ),
                  if (_isToday)
                    GestureDetector(
                      onTap: _showPriorityDialog,
                      child: widget.caseItem.priorityNumber == null
                          ? Container(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                              decoration: BoxDecoration(
                                color: widget.isHighlighted
                                    ? Colors.white
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: cardColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Priority',
                                    style: TextStyle(
                                      color: cardColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isHighlighted
                                    ? Colors.white
                                    : Colors.black,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${widget.caseItem.priorityNumber}',
                                style: TextStyle(
                                  color: widget.isHighlighted
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),

            Divider(
              color: Colors.black87,
              thickness: 1,
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parties information with VS highlighted and icon
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        size: 16,
                        color: accentColor,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              height: 1.3,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    widget.caseItem.applicant.capitalize ?? '',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: ' vs ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: widget.isHighlighted
                                      ? Colors.red.shade300
                                      : Colors.red.shade700,
                                ),
                              ),
                              TextSpan(
                                text: widget.caseItem.opponent.capitalize ?? '',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.black54,
                    thickness: 0.6,
                  ),

                  // Case details in a single-line format
                  _buildSingleLineInfo(
                    icon: Icons.calendar_today,
                    label: 'Summon Date:',
                    value: _formatDate(widget.caseItem.srDate),
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  Divider(
                    color: Colors.black54,
                    thickness: 0.6,
                  ),

                  _buildSingleLineInfo(
                    icon: Icons.gavel,
                    label: 'Court:',
                    value: widget.caseItem.courtName,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  Divider(
                    color: Colors.black54,
                    thickness: 0.6,
                  ),

                  _buildSingleLineInfo(
                    icon: Icons.location_city,
                    label: 'City:',
                    value: widget.caseItem.cityName,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  Divider(
                    color: Colors.black54,
                    thickness: 0.6,
                  ),

                  _buildSingleLineInfo(
                    icon: Icons.hourglass_bottom,
                    label: 'Case Counter:',
                    value: (widget.caseItem.caseCounter.isEmpty ||
                            widget.caseItem.caseCounter == 'null')
                        ? "Not Available"
                        : "${widget.caseItem.caseCounter} days",
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  // Remarks section
                  if (widget.caseItem.remark != null &&
                      widget.caseItem.remark != '' &&
                      widget.caseItem.remark != 'null')
                    Container(
                      margin: EdgeInsets.only(top: 14),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isHighlighted
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isHighlighted
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.comment,
                                size: 16,
                                color: accentColor,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Remark',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            widget.caseItem.remark ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleLineInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: accentColor,
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: accentColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
