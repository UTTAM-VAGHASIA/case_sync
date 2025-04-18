import 'dart:convert';

import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../models/advocate.dart';
import '../../../services/shared_pref.dart';
import '../../../utils/validator.dart';
import '../../constants/constants.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> taskDetails;

  const EditTaskScreen({
    super.key,
    required this.taskDetails,
  });

  @override
  State<EditTaskScreen> createState() => EditTaskScreenState();
}

class EditTaskScreenState extends State<EditTaskScreen> {
  String? _advocateName;
  String? _advocateId;
  String? _assignedTo;
  String _assignDateDisplay = '';
  String _expectedEndDateDisplay = '';
  String _assignDateApi = '';
  String _expectedEndDateApi = '';
  String? _selectedStatus;
  final _taskInstructionController = TextEditingController();

  List<Map<String, String>> _internList = [];
  List<Map<String, String>> _advocateList = [];

  String? selectedRole;
  List<dynamic> dropdownItems = [];

  bool isAssigned = false;
  bool isEnded = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    _fetchBothLists();
    getUsername();
  }

  Future<void> _fetchBothLists() async {
    await _fetchInternList();
    await _fetchAdvocateList();
    _populateTaskDetails();
    setState(() {
      isLoading = false;
    });
  }

  void _populateTaskDetails() {
    final task = widget.taskDetails;
    _assignedTo = task['alloted_to_id'];
    print(_assignedTo);
    // Determine the role based on the alloted_to_id
    if (_assignedTo != null) {
      bool isIntern = _internList.any((intern) => intern['id'] == _assignedTo);
      selectedRole = isIntern ? 'Intern' : 'Advocate';
      print(selectedRole);
    }
    _taskInstructionController.text = task['instruction'] ?? '';
    if (task['alloted_date'] != null && task['alloted_date'].isNotEmpty) {
      _assignDateDisplay =
          DateFormat('dd/MM/yyyy').format(DateTime.parse(task['alloted_date']));
      _assignDateApi =
          DateFormat('yyyy/MM/dd').format(DateTime.parse(task['alloted_date']));
    } else {
      _assignDateDisplay = "Not Assigned";
      _assignDateApi = "";
    }
    if (task['expected_end_date'] != null &&
        task['expected_end_date'].isNotEmpty) {
      _expectedEndDateDisplay = DateFormat('dd/MM/yyyy')
          .format(DateTime.parse(task['expected_end_date']));
      _expectedEndDateApi = DateFormat('yyyy/MM/dd')
          .format(DateTime.parse(task['expected_end_date']));
    } else {
      _expectedEndDateDisplay = "No End Date";
      _expectedEndDateApi = "";
    }
    _selectedStatus = widget.taskDetails['status'];
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

  Future<void> _fetchAdvocateList() async {
    final url = '$baseUrl/get_advocate_list';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _advocateList = (data['data'] as List)
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
    SnackBarUtils.showErrorSnackBar(context, message);
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
          _expectedEndDateDisplay = date;
          _expectedEndDateApi = apiDate;
          print(_expectedEndDateApi);
          print(_expectedEndDateDisplay);
          isEnded = true;
        } else {
          _assignDateDisplay = date;
          _assignDateApi = apiDate;
          print(_assignDateApi);
          print(_assignDateDisplay);
          isAssigned = true;
        }
      });
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _updateTask() async {
    setState(() {
      isLoading = true;
    });
    if (_advocateName == null ||
        _assignedTo == null ||
        validateTaskInstruction(_taskInstructionController.text) != null) {
      SnackBarUtils.showErrorSnackBar(context, "Please fill out all fields");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = '$baseUrl/edit_task';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['data'] = jsonEncode({
        "task_id": widget.taskDetails['id'],
        "case_id": widget.taskDetails['case_id'],
        "alloted_to": _assignedTo,
        "instructions": _taskInstructionController.text.trim(),
        "alloted_by": _advocateId,
        "alloted_date": _assignDateApi,
        "expected_end_date": _expectedEndDateApi,
        "status": _selectedStatus,
        "remark": "Updated task",
      });

      print(request.fields);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && decodedResponse['success'] == true) {
        SnackBarUtils.showSuccessSnackBar(
            context, "Task updated successfully!");
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar(
            "Failed to update task: ${decodedResponse['message'] ?? response.statusCode}");
      }
    } catch (error) {
      _showErrorSnackBar("Error updating task: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: const Color(0xFFF3F3F3),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                  'Edit Task',
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
                label: 'Task Instructions',
                hint: 'Enter instructions',
                controller: _taskInstructionController,
                maxLines: null,
              ),
              const SizedBox(height: 20),
              Text(
                'Assigned To',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // Center buttons
                children: [
                  _buildRoleButton('Intern'),
                  const SizedBox(width: 12),
                  _buildRoleButton('Advocate'),
                ],
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Assigned to',
                hint: 'Select $selectedRole',
                value: _assignedTo,
                items: selectedRole == 'Intern' ? _internList : _advocateList,
                onChanged: (value) => setState(() => _assignedTo = value),
                isLabeled: false,
                isDisabled: true,
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Assign Date',
                hint: _assignDateDisplay,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _selectDate(context, false);
                },
                isSelected: isAssigned,
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Expected End Date',
                hint: _expectedEndDateDisplay,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _selectDate(context, true);
                },
                isSelected: isEnded,
              ),
              const SizedBox(height: 20),
              Text('Status', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              IgnorePointer(
                ignoring: true,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ['pending', 'completed', 're_alloted', 'allotted']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status
                                  .split('_')
                                  .map((word) =>
                                      word[0].toUpperCase() + word.substring(1))
                                  .join(' '),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                  iconEnabledColor: Colors.transparent,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _updateTask();
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
                      : const Text(
                          'Update Task',
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

  // Enhanced Role Button
  Widget _buildRoleButton(String role) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedRole == role ? Colors.black : Colors.white,
          foregroundColor: selectedRole == role ? Colors.white : Colors.black,
          elevation: 2,
          // Subtle shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: Colors.black, width: 1),
        ),
        child: Text(
          role,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Enhanced Dropdown Field
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    bool isLabeled = true,
    bool isDisabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLabeled)
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        if (isLabeled) const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IgnorePointer(
            ignoring: isDisabled,
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              
              hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item['id'],
                        child: Text(item['name']!),
                      ))
                  .toList(),
              onChanged: onChanged,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              iconEnabledColor: (isDisabled) ? Colors.transparent : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
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

  Widget _buildDateField({
    required String label,
    required String hint,
    required VoidCallback onTap,
    required bool isSelected,
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
                Text(hint,
                    style: TextStyle(
                        color: isSelected ? Colors.black : Colors.grey)),
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
