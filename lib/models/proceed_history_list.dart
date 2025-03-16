class ProceedHistoryListData {
  final String id;
  final String caseId;
  final String nextStage;
  final DateTime nextDate;
  final String remark;
  final String insertedBy;
  final DateTime dateOfCreation;
  final String stage;

  ProceedHistoryListData({
    required this.id,
    required this.caseId,
    required this.nextStage,
    required this.nextDate,
    required this.remark,
    required this.insertedBy,
    required this.dateOfCreation,
    required this.stage,
  });

  factory ProceedHistoryListData.fromJson(Map<String, dynamic> json) {
    return ProceedHistoryListData(
      id: json['id'] ?? '',
      caseId: json['case_id'] ?? '',
      nextStage: json['next_stage'] ?? '',
      nextDate: json['next_date'] != '' && json['next_date'] != null
          ? DateTime.parse(json['next_date'])
          : DateTime.parse('0001-01-01'),
      remark: json['remarks'] ?? '',
      insertedBy: json['inserted_by'] ?? '',
      dateOfCreation:
          json['date_of_creation'] != '' && json['date_of_creation'] != null
              ? DateTime.parse(json['date_of_creation'])
              : DateTime.parse('0001-01-01'),
      stage: json['stage'] ?? '',
    );
  }
}
