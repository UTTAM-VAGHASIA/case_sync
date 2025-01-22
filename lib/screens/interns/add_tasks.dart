import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/advocate.dart';
import '../../services/shared_pref.dart';

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
  String? _advocateid;
  String? _assignedTo;
  String? _assignDate;
  String? _expectedEndDate;
  final _taskInstructionController = TextEditingController();
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
      _advocateid = user.id;
    });
  }

  @override
  void dispose() {
    _taskInstructionController.dispose();
    super.dispose();
  }

  Future<void> _fetchInternList() async {
    const url =
        'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_interns_list';
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        final date = "${picked.year}/${picked.month}/${picked.day}";
        if (isEndDate) {
          _expectedEndDate = date;
        } else {
          _assignDate = date;
        }
      });
    }
  }

  Future<void> _confirmTask() async {
    if (_advocateName == null ||
        _assignedTo == null ||
        _taskInstructionController.text.isEmpty ||
        _assignDate == null ||
        _expectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill out all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    const url =
        'https://pragmanxt.com/case_sync/services/admin/v1/index.php/add_task';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['data'] = jsonEncode({
        "case_id": widget.caseId,
        "alloted_to": _assignedTo,
        "instructions": _taskInstructionController.text,
        "alloted_by": _advocateid,
        "alloted_date": _assignDate,
        "expected_end_date": _expectedEndDate,
        "status": "pending",
        "remark": "Some remark",
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && decodedResponse['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);  // Return true to indicate a successful task addition
      } else {
        _showErrorSnackBar(
            "Failed to add task: ${decodedResponse['message'] ?? response.statusCode}");
      }
    } catch (error) {
      _showErrorSnackBar("Error adding task: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
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
                'Add\nTask',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(
              label: 'Case Number',
              hint: widget.caseNumber,
              controller: TextEditingController(text: widget.caseNumber),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Case Type',
              hint: widget.caseType,
              controller: TextEditingController(text: widget.caseType),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Assigned by',
              hint: _advocateid ?? '',
              controller: TextEditingController(text: _advocateName ?? ''),
              readOnly: true,
            ),
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
              hint: _assignDate ?? 'Select Date',
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 20),
            _buildDateField(
              label: 'Expected End Date',
              hint: _expectedEndDate ?? 'Select Date',
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _confirmTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
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
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(hint, style: const TextStyle(color: Colors.grey)),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
