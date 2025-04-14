import 'dart:convert';

import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:case_sync/utils/snackbar_utils.dart';

import '../screens/constants/constants.dart';

class UpdateStageModal extends StatefulWidget {
  final String? proceedingId;
  final String? insertedBy;
  final bool isEditing;
  final String caseId;
  final DateTime initialDate;
  final String? initialStage;
  final List<Map<String, dynamic>> stageList;
  final String? initialRemark;

  const UpdateStageModal({
    super.key,
    this.proceedingId,
    required this.initialDate,
    required this.initialStage,
    required this.stageList,
    required this.caseId,
    this.isEditing = false,
    this.insertedBy,
    this.initialRemark,
  });

  @override
  UpdateStageModalState createState() => UpdateStageModalState();
}

class UpdateStageModalState extends State<UpdateStageModal> {
  final _remarkController = TextEditingController();
  late DateTime selectedDate;
  String? selectedStage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedStage = widget.stageList
            .any((item) => item['id'].toString() == widget.initialStage)
        ? widget.initialStage
        : null;
    _remarkController.text = widget.initialRemark ?? "";

    print("UpdateStageModal");
    print("Initial date: ${DateFormat('yyyy/MM/dd').format(selectedDate)}");
    print("Initial stage: $selectedStage");
    print("Stage list: ${widget.stageList}");
    print("Case ID: $widget.caseId");
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _updateNextStage(DateTime nextDate, String nextStage) async {
    setState(() {
      isLoading = true;
    });
    final advocate = await SharedPrefService.getUser();
    final advocateId = advocate!.id;
    try {
      final url = Uri.parse('$baseUrl/proceed_case_add');
      var request = http.MultipartRequest("POST", url);
      request.fields['data'] = jsonEncode({
        "case_id": widget.caseId,
        "next_date": DateFormat('yyyy/MM/dd').format(nextDate),
        "next_stage": nextStage,
        "remark": _remarkController.text,
        "inserted_by": advocateId,
      });

      print(request.fields['data']);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['success'] == true) {
        if (mounted) {
          SnackBarUtils.showSuccessSnackBar(
            context,
            "Stage updated successfully!",
          );
        }
      } else {
        if (mounted) {
          SnackBarUtils.showErrorSnackBar(
            context,
            data['message'] ?? "Failed to update.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(
          context,
          "An error occurred.",
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _editProceeding(String proceedingId, String caseId,
      DateTime nextDate, String nextStage, String advocateId) async {
    setState(() {
      isLoading = true;
    });
    final advocate = await SharedPrefService.getUser();
    final advocateId = advocate!.id;
    try {
      final url = Uri.parse('$baseUrl/proceed_case_edit');
      var request = http.MultipartRequest("POST", url);
      request.fields['data'] = jsonEncode({
        "proceed_id": proceedingId,
        "case_id": caseId,
        "next_date": DateFormat('yyyy/MM/dd').format(nextDate),
        "next_stage": nextStage,
        "remark": _remarkController.text,
        "inserted_by": advocateId,
      });

      print(request.fields['data']);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['success'] == true) {
        if (mounted) {
          SnackBarUtils.showSuccessSnackBar(
            context,
            "Stage updated successfully!",
          );
        }
      } else {
        if (mounted) {
          SnackBarUtils.showErrorSnackBar(
            context,
            data['message'] ?? "Failed to update.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(
          context,
          "An error occurred.",
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Proceed the case",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1800),
                lastDate: DateTime(2200),
              );
              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('dd-MM-yyyy').format(selectedDate),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today, color: Colors.black),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: InputDecoration(
              hintText: "Select Next Stage",
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
            value: selectedStage,
            items: widget.stageList.map((item) {
              return DropdownMenuItem<String>(
                value: item['id'],
                child:
                    Text(item['stage'].trim(), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedStage = value),
          ),
          const SizedBox(
            height: 16,
          ),
          _buildTextField(
            hint: 'Add Remark Here',
            controller: _remarkController,
            maxLines: null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (isLoading) ? null : () async {
              HapticFeedback.mediumImpact();
              if (!widget.isEditing) {
                await _updateNextStage(
                    selectedDate, selectedStage ?? widget.initialStage!);
              } else {
                await _editProceeding(
                    widget.proceedingId!,
                    widget.caseId,
                    selectedDate,
                    selectedStage ?? widget.initialStage!,
                    widget.insertedBy!);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: (isLoading)
                ? CircularProgressIndicator(
                  color: Colors.white,
                )
                : Text(
                    "Update",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
