import 'package:intl/intl.dart';

class TaskItem {
  final String intern_id;
  final String caseNo;
  final String instruction;
  final String allotedTo;
  final String alloted_to_id;
  final String allotedBy;
  final String alloted_by_id;
  final DateTime? allotedDate;
  final String added_by;
  final DateTime? expectedEndDate;
  final String status;
  final String task_id;
  final String stage;
  final String case_id;
  final String stage_id;
  final String case_type;

  TaskItem({
    required this.intern_id,
    required this.caseNo,
    required this.instruction,
    required this.allotedTo,
    required this.alloted_to_id,
    required this.allotedBy,
    required this.alloted_by_id,
    required this.added_by,
    this.allotedDate,
    this.expectedEndDate,
    required this.status,
    required this.task_id,
    required this.stage,
    required this.case_id,
    required this.stage_id,
    required this.case_type,
  });

   factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      intern_id: json['intern_id'] ?? '',
      caseNo: json['case_no'] ?? '',
      instruction: (json['instruction'] ?? '').trim(),
      allotedTo: json['alloted_to'] ?? '',
      alloted_to_id: json['alloted_to_id'] ?? '',
      allotedBy: json['alloted_by'] ?? '',
      alloted_by_id: json['alloted_by_id'] ?? '',
      added_by: json['added_by'] ?? '',
      allotedDate: json['alloted_date'] != null
          ? DateTime.tryParse(json['alloted_date'])
          : null,
      expectedEndDate: json['expected_end_date'] != null
          ? DateTime.tryParse(json['expected_end_date'])
          : null,
      status: json['status'] ?? '',
      task_id: json['task_id'] ?? '',
      stage: json['stage'] ?? '',
      case_id: json['case_id'] ?? '',
      stage_id: json['stage_id'] ?? '',
      case_type: json['case_type'] ?? '',
    );
  }

  static Map<String, dynamic> toJson(TaskItem task) {
    final Map<String, dynamic> data = {};

    void addIfNotEmpty(String key, dynamic value) {
      if (value != null && (value is! String || value.trim().isNotEmpty)) {
        data[key] = value;
      }
    }

    addIfNotEmpty('intern_id', task.intern_id);
    addIfNotEmpty('case_no', task.caseNo);
    addIfNotEmpty('instruction', task.instruction);
    addIfNotEmpty('alloted_to', task.allotedTo);
    addIfNotEmpty('alloted_to_id', task.alloted_to_id);
    addIfNotEmpty('alloted_by', task.allotedBy);
    addIfNotEmpty('alloted_by_id', task.alloted_by_id);
    addIfNotEmpty('added_by', task.added_by);
    addIfNotEmpty('alloted_date', task.allotedDate?.toIso8601String());
    addIfNotEmpty('expected_end_date', task.expectedEndDate?.toIso8601String());
    addIfNotEmpty('status', task.status);
    addIfNotEmpty('id', task.task_id);
    addIfNotEmpty('stage', task.stage);
    addIfNotEmpty('case_id', task.case_id);
    addIfNotEmpty('stage_id', task.stage_id);
    addIfNotEmpty('case_type', task.case_type);

    return data;
  }

  /// Get formatted date in `dd/MM/yy` format
  String get formattedAllotedDate => allotedDate != null
      ? DateFormat('dd/MM/yyyy').format(allotedDate!)
      : 'N/A';

  String get formattedExpectedEndDate => expectedEndDate != null
      ? DateFormat('dd/MM/yyyy').format(expectedEndDate!)
      : 'N/A';
}
