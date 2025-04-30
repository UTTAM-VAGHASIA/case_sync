import 'dart:convert';

// Assuming Advocate model is accessible
import 'package:case_sync/models/advocate.dart'; // Assuming these are accessible or defined elsewhere
import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ReAssignTaskSheet extends StatefulWidget {
  final String taskId;
  final String advocateId; // The current advocate/assignee

  const ReAssignTaskSheet({
    super.key,
    required this.taskId,
    required this.advocateId,
  });

  @override
  State<ReAssignTaskSheet> createState() => _ReAssignTaskSheetState();
}

class _ReAssignTaskSheetState extends State<ReAssignTaskSheet> {
  final TextEditingController _remarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // --- State for Role Selection ---
  String _selectedRole = 'Intern'; // Default role
  String? _selectedAssigneeId; // ID of selected intern OR advocate
  List<Map<String, String>> _internList = [];
  List<Map<String, String>> _advocateList = [];

  // --- End State for Role Selection ---

  String? _loggedInUserId;
  String? _loggedInUserName; // Store name for display if needed

  // --- Loading and Error States ---
  bool _isLoading = false; // For the main reassign action
  bool _isFetchingInterns = false;
  bool _isFetchingAdvocates = false;
  String? _fetchInternError;
  String? _fetchAdvocateError;

  // --- End Loading and Error States ---

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Start fetching everything concurrently
    setState(() {
      _isFetchingInterns = true;
      _isFetchingAdvocates = true;
      _fetchInternError = null;
      _fetchAdvocateError = null;
    });

    // Fetch logged-in user first
    await _fetchLoggedInUserId();

    // Fetch both lists concurrently if user ID found
    if (_loggedInUserId != null) {
      await Future.wait([
        _fetchInternList(),
        _fetchAdvocateList(),
      ]);
    } else {
      // Handle case where logged-in user couldn't be identified
      if (mounted) {
        setState(() {
          _isFetchingInterns = false;
          _isFetchingAdvocates = false;
          _fetchInternError = "Could not identify logged-in user.";
          _fetchAdvocateError = "Could not identify logged-in user.";
        });
      }
    }

    // Ensure loading flags are false if component is unmounted during fetch
    if (!mounted) return;

    // Update state after fetches complete (even if one failed)
    setState(() {
      _isFetchingInterns = false;
      _isFetchingAdvocates = false;
    });
  }

  Future<void> _fetchLoggedInUserId() async {
    final Advocate? userData = await SharedPrefService.getUser();
    if (mounted && userData != null && userData.id.isNotEmpty) {
      setState(() {
        _loggedInUserId = userData.id;
        _loggedInUserName = userData.name;
      });
    }
    // Handle case where user data isn't found if necessary
  }

  // Fetch Intern List (excluding logged-in user)
  Future<void> _fetchInternList() async {
    if (_loggedInUserId == null) return; // Guard if user ID failed

    final String apiUrl = '$baseUrl/get_interns_list'; // Ensure baseUrl is correct

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final List<dynamic> allInterns = responseData['data'] ?? [];
          setState(() {
            _internList = allInterns
                .where((item) =>
                    item['id']?.toString() != null &&
                    item['name']?.toString() != null &&
                    item['id'].toString() != _loggedInUserId) // Exclude self
                .map((item) => {
                      'id': item['id'].toString(),
                      'name': item['name'].toString(),
                    })
                .toList();
            _fetchInternError =
                _internList.isEmpty ? 'No other interns available.' : null;
          });
        } else {
          setState(() => _fetchInternError =
              responseData['message'] ?? 'Failed to load interns.');
        }
      } else {
        setState(
            () => _fetchInternError = 'Server Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _fetchInternError = 'Error: $e');
    }
  }

  // Fetch Advocate List (excluding logged-in user)
  Future<void> _fetchAdvocateList() async {
    if (_loggedInUserId == null) return; // Guard if user ID failed

    final String apiUrl = '$baseUrl/get_advocate_list'; // Ensure baseUrl is correct

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final List<dynamic> allAdvocates = responseData['data'] ?? [];
          setState(() {
            _advocateList = allAdvocates
                .where((item) =>
                    item['id']?.toString() != null &&
                    item['name']?.toString() != null)
                // && item['id'].toString() != _loggedInUserId) // Exclude self
                .map((item) => {
                      'id': item['id'].toString(),
                      'name': item['name'].toString(),
                    })
                .toList();
            _fetchAdvocateError =
                _advocateList.isEmpty ? 'No other advocates available.' : null;
          });
        } else {
          setState(() => _fetchAdvocateError =
              responseData['message'] ?? 'Failed to load advocates.');
        }
      } else {
        setState(
            () => _fetchAdvocateError = 'Server Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _fetchAdvocateError = 'Error: $e');
    }
  }

  Future<void> _reassignTask() async {
    // Use _selectedAssigneeId now
    if (_selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select an $_selectedRole to assign to.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    // Optional: Add remark validation if needed
    // if (_remarkController.text.trim().isEmpty) { ... }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$baseUrl/task_reassign');
    var request = http.MultipartRequest('POST', url);

    request.fields['data'] = jsonEncode({
      "task_id": widget.taskId,
      "assigned_id": widget.advocateId, // Current assignee
      "reassign_id": _selectedAssigneeId, // New assignee (Intern or Advocate)
      "remark": _remarkController.text.trim(),
      "remark_date":
          DateFormat('yyyy-MM-dd').format(_selectedDate), // Standard format
    });

    print("Reassigning Task....");
    print(request.fields['data']);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (!mounted) return;
      final responseData = json.decode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData['message'] ?? 'Task reassigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Close sheet and signal success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                'Reassignment failed. Server: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  // --- Helper Widgets ---

  // Role selection button (Adapted from AddTaskScreen)
  Widget _buildRoleButton(String role) {
    final bool isActive = _selectedRole == role;
    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading || _isFetchingInterns || _isFetchingAdvocates
            ? null
            : () {
                // Disable while loading/fetching
                if (_selectedRole != role) {
                  setState(() {
                    _selectedRole = role;
                    _selectedAssigneeId =
                        null; // Reset selection when role changes
                    // Optionally trigger fetch here if not done in initState
                  });
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.black : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.black,
          elevation: isActive ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: isActive ? Colors.black : Colors.grey.shade400,
                width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          role,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Text field decoration
  static InputDecoration textFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  // --- End Helper Widgets ---

  @override
  Widget build(BuildContext context) {
    // Determine current list, fetch status, and error based on selected role
    final bool isInternSelected = _selectedRole == 'Intern';
    final List<Map<String, String>> currentList =
        isInternSelected ? _internList : _advocateList;
    final bool isFetchingCurrentList =
        isInternSelected ? _isFetchingInterns : _isFetchingAdvocates;
    final String? currentFetchError =
        isInternSelected ? _fetchInternError : _fetchAdvocateError;
    final bool canSubmit = !isFetchingCurrentList &&
        currentFetchError == null &&
        currentList.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            // Title
            Text('Reassign Task',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- Role Selection ---
            const Text('Assign To:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRoleButton('Intern'),
                const SizedBox(width: 10),
                _buildRoleButton('Advocate'),
              ],
            ),
            const SizedBox(height: 12),
            // --- End Role Selection ---

            // --- Assignee Dropdown ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: isFetchingCurrentList
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))))
                  : currentFetchError != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(currentFetchError,
                              style: TextStyle(color: Colors.red.shade700)))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedAssigneeId,
                            hint: Text('Select an $_selectedRole'),
                            items: currentList
                                .map((item) => DropdownMenuItem<String>(
                                      value: item['id'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedAssigneeId = value;
                                    });
                                  },
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            menuMaxHeight: 250,
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            // --- End Assignee Dropdown ---

            // Remark Input
            const Text('Remark:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _remarkController,
              decoration: textFieldDecoration('Enter remark (optional)'),
              maxLines: null,
              readOnly: _isLoading,
            ),
            const SizedBox(height: 16),

            // Date Selection
            const Text('Remark Date:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isLoading ? null : () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          DateFormat('dd MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16)),
                    ),
                    Icon(Icons.calendar_today, color: Colors.grey.shade700),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Action Button
            Center(
              child: ElevatedButton(
                // Disable button if any list is fetching, or the current list has error/is empty, or main action is loading
                onPressed: _isLoading ||
                        _isFetchingInterns ||
                        _isFetchingAdvocates ||
                        !canSubmit
                    ? null
                    : _reassignTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Reassign Task',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }
}
