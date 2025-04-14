import 'dart:convert';

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddRemarkModal extends StatefulWidget {
  final String? currentStage;

  final String taskId;

  final String caseId;

  final String stageId;

  final bool isEditing;

  const AddRemarkModal(
      {super.key,
      required this.currentStage,
      required this.taskId,
      required this.caseId,
      required this.stageId,
      this.isEditing = false});

  @override
  AddRemarkModalState createState() => AddRemarkModalState();
}

class AddRemarkModalState extends State<AddRemarkModal> {
  final _remarkController = TextEditingController();
  late DateTime selectedDate;
  String selectedStatus = "pending";
  String? userId;
  bool isLoading = false;

  String? _fileNames;
  String? _filePaths;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _addRemark(
    String taskId,
    String remark,
    String currentStageId,
    DateTime remarkDate,
    String caseId,
    String status,
    List<String?> file,
  ) async {
    setState(() {
      isLoading = true;
    });
    userId = (await SharedPrefService.getUser())!.id;
    try {
      final url = Uri.parse('$baseUrl/add_task_remark');
      var request = http.MultipartRequest("POST", url);
      request.fields['data'] = jsonEncode({
        "task_id": taskId,
        "remark": remark,
        "stage_id": currentStageId,
        "remark_date": DateFormat('yyyy/MM/dd').format(remarkDate),
        "case_id": caseId,
        "inserted_by": userId,
        "status": status
      });

      if (file[1] != null) {
        request.files
            .add(await http.MultipartFile.fromPath('task_image', file[1]!));
      }

      print("Remark data: ${request.fields['data']!}");

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['success'] == true) {
        if (mounted) {
          SnackBarUtils.showSuccessSnackBar(
            context,
            "Remark Added successfully!",
          );
        }
      } else {
        if (mounted) {
          SnackBarUtils.showErrorSnackBar(
            context,
            data['message'] ?? "Failed to add remark.",
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

  Future<void> _pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        // Append newly selected files to the existing list.
        _fileNames = result.files.first.name;
        _filePaths = result.files.first.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
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
              // Stage (Non-Editable)
              _buildSectionLabel("Stage"),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  widget.currentStage ?? "No Current Stage",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 16),

              // Remark Text Field
              _buildSectionLabel("Remark"),
              TextFormField(
                controller: _remarkController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Enter your remark here",
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Date Picker
              _buildSectionLabel("Remark Date"),
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('dd-MM-yyyy').format(selectedDate),
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today, color: Colors.black45),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status Dropdown
              _buildSectionLabel("Status"),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: "Select Status",
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: selectedStatus,
                // Default value
                items: const [
                  DropdownMenuItem(value: "pending", child: Text("Pending")),
                  DropdownMenuItem(
                      value: "completed", child: Text("Completed")),
                ],
                onChanged: (value) {
                  setState(() {
                    // Handle status change here
                    selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // File Picker
              _buildSectionLabel("Attach Files"),
              GestureDetector(
                onTap: _pickDocument,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.black45),
                      const SizedBox(width: 8),
                      Text(
                        _fileNames ?? "Tap to select files",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected Files
              if (_fileNames != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _fileNames!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() {
                          _fileNames = null;
                          _filePaths = null;
                        }),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:(isLoading) ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isLoading)
                          ? null
                          : () async {
                              if (!widget.isEditing) {
                                await _addRemark(
                                  widget.taskId,
                                  _remarkController.text,
                                  widget.stageId,
                                  selectedDate,
                                  widget.caseId,
                                  selectedStatus,
                                  [_fileNames, _filePaths],
                                );
                              } else {
                                // _editProceeding(
                                //     widget.taskId,
                                //     widget.caseId,
                                //     selectedDate,
                                //     selectedStage ?? widget.currentStage!,
                                //     userId!);
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: (isLoading)
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              "Save",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

// Helper Widgets
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
