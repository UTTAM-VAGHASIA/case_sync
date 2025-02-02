import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'constants.dart';

class UpdateStageModal extends StatefulWidget {
  final String caseId;
  final DateTime initialDate;
  final String? initialStage;
  final List<Map<String, dynamic>> stageList;

  const UpdateStageModal({
    super.key,
    required this.initialDate,
    required this.initialStage,
    required this.stageList,
    required this.caseId,
  });

  @override
  UpdateStageModalState createState() => UpdateStageModalState();
}

class UpdateStageModalState extends State<UpdateStageModal> {
  late DateTime selectedDate;
  String? selectedStage;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedStage = widget.initialStage;
  }

  Future<void> _updateNextStage(DateTime nextDate, String nextStage) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final url = Uri.parse('$baseUrl/next_stage');
      var request = http.MultipartRequest("POST", url);
      request.fields['data'] = jsonEncode({
        "case_id": widget.caseId,
        "next_date": DateFormat('yyyy/MM/dd').format(nextDate),
        "next_stage": nextStage
      });

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['success'] == true) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Stage updated successfully!")),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to update.")),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("An error occurred.")),
      );
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
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _updateNextStage(
                  selectedDate, selectedStage ?? widget.initialStage!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Update",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
