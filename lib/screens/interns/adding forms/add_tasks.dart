import 'dart:convert';

import 'package:case_sync/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../models/advocate.dart';
import '../../../services/shared_pref.dart';
import '../../../utils/validator.dart';

class AddTaskScreen extends StatefulWidget {
  final String caseNumber;
  final String caseType;
  final String caseId;

  const AddTaskScreen({
    super.key,
    required this.caseNumber,
    required this.caseType,
    required this.caseId,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  String? _advocateName;
  String? _advocateId;
  String? _assignedTo;
  String? _assignDateDisplay = DateFormat('dd/MM/yyyy').format(DateTime.now());
  late String? _expectedEndDateDisplay =
      DateFormat('dd/MM/yyyy').format(DateTime.now());
  String? _assignDateApi = DateFormat('yyyy/MM/dd').format(DateTime.now());
  String? _expectedEndDateApi = DateFormat('yyyy/MM/dd').format(DateTime.now());
  final _taskInstructionController = TextEditingController();
  bool isAssigned = false;
  bool isExpected = false;
  bool isSelected = false;
  bool isLoading = false;

  List<Map<String, String>> _internList = [];

  @override
  void initState() {
    super.initState();
    _fetchInternList();
    getUsername();
  }

  Future<void> getUsername() async {
    Advocate? user = await SharedPrefService.getUser();
    if (user == null) {
      throw Exception('User not found. Please log in again.');
    }
    setState(() {
      _advocateName = user.name;
      _advocateId = user.id;
    });
  }

  @override
  void dispose() {
    _taskInstructionController.dispose();
    super.dispose();
  }

  Future<void> _fetchInternList() async {
    final url = '$baseUrl/get_interns_list';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _internList = (data['data'] as List)
                .map((intern) => {
                      'id': intern['id'].toString(),
                      'name': intern['name'].toString(),
                    })
                .toList();
          });
        } else {
          _showErrorSnackBar('Failed to load intern list.');
        }
      } else {
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackBar('Failed to fetch data: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isEndDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() {
        final date = DateFormat('dd/MM/yyyy').format(picked);
        final apiDate = DateFormat('yyyy/MM/dd').format(picked);
        if (isEndDate) {
          isExpected = true;
          _expectedEndDateDisplay = date;
          _expectedEndDateApi = apiDate;
        } else {
          isAssigned = true;
          _assignDateDisplay = date;
          _assignDateApi = apiDate;
        }
      });
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _confirmTask() async {
    setState(() {
      isLoading = true;
    });
    if (_advocateName == null ||
        _assignedTo == null ||
        validateTaskInstruction(_taskInstructionController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill out all fields"),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = '$baseUrl/add_task';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['data'] = jsonEncode({
        "case_id": widget.caseId,
        "alloted_to": _assignedTo,
        "instructions": _taskInstructionController.text
            .trim(), // Trim here before submitting
        "alloted_by": _advocateId,
        "alloted_date": _assignDateApi,
        "expected_end_date": _expectedEndDateApi,
        "status": "alloted",
        "remark": "",
      });

      // Debugging logs
      print("Request Payload: ${request.fields['data']}");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);

      print("API Response: $decodedResponse");

      if (response.statusCode == 200 && decodedResponse['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar(
            "Failed to add task: ${decodedResponse['message'] ?? response.statusCode}");
      }
    } catch (error) {
      _showErrorSnackBar("Error adding task: $error");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.caseNumber);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: const Color(0xFFF3F3F3),
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Add Task',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              // _buildTextField(
              //   label: 'Case Number',
              //   hint: widget.caseNumber,
              //   controller: TextEditingController(text: widget.caseNumber),
              //   readOnly: true,
              // ),
              // const SizedBox(height: 20),
              // _buildTextField(
              //   label: 'Case Type',
              //   hint: widget.caseType,
              //   controller: TextEditingController(text: widget.caseType),
              //   readOnly: true,
              // ),
              // const SizedBox(height: 20),
              // _buildTextField(
              //   label: 'Assigned by',
              //   hint: _advocateId ?? '',
              //   controller: TextEditingController(text: _advocateName ?? ''),
              //   readOnly: true,
              // ),
              _buildGeneralInfoCard(),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Assign to',
                hint: 'Select Intern',
                value: _assignedTo,
                items: _internList,
                onChanged: (value) => setState(() => _assignedTo = value),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Task Instruction',
                hint: 'Instructions',
                controller: _taskInstructionController,
              ),
              const SizedBox(height: 20),
              _buildDateField(
                  label: 'Assign Date',
                  child: Text(
                    _assignDateDisplay ?? 'Select Date',
                    style: TextStyle(
                      color: isAssigned ? Colors.black : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _selectDate(context, false);
                  }),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Expected End Date',
                child: Text(
                  _expectedEndDateDisplay ?? 'Select Date',
                  style: TextStyle(
                    color: isExpected ? Colors.black : Colors.grey,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _selectDate(context, true);
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    isLoading ? null : _confirmTask();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    final List<MapEntry<String, String>> generalInfo = [
      MapEntry('Case Type', widget.caseType),
      MapEntry('Advocate Name', _advocateName.toString()),
    ];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Colors.black,
          width: 1,
        ),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Text(
                  'Case No.: ${widget.caseNumber}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const Divider(
                  thickness: 2,
                  color: Colors.black,
                ),
                // Key-Value Rows
                ...generalInfo.map((entry) {
                  String displayValue =
                      entry.value.isNotEmpty ? entry.value : '-';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              displayValue,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      if (generalInfo.last != entry)
                        Divider(
                          thickness: 1,
                          color: Colors.black38,
                        )
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
              border: InputBorder.none,
            ),
            hint: Text(hint, style: const TextStyle(color: Colors.grey)),
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item['id'],
                      child: Text(item['name']!),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          readOnly: readOnly,
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

  Widget _buildDateField({
    required String label,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Row(
              children: [
                child,
                const Spacer(),
                const Icon(Icons.calendar_today, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
