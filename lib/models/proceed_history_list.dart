class ProceedHistoryListData {
  final String id;
  final String caseId;
  final String stageName;
  final DateTime nextDate;
  final String remark;
  final String insertedBy;
  final DateTime dateOfCreation;
  final String nextStageId;

  final String insertedByName;

  ProceedHistoryListData(
      {required this.id,
      required this.caseId,
      required this.stageName,
      required this.nextDate,
      required this.remark,
      required this.insertedBy,
      required this.dateOfCreation,
      required this.nextStageId,
      required this.insertedByName});

  factory ProceedHistoryListData.fromJson(Map<String, dynamic> json) {
    return ProceedHistoryListData(
        id: json['id'] ?? '',
        caseId: json['case_id'] ?? '',
        nextStageId: json['next_stage'] ?? '',
        nextDate: json['next_date'] != '' && json['next_date'] != null
            ? DateTime.parse(json['next_date'])
            : DateTime.parse('0001-01-01'),
        remark: json['remarks'] ?? '',
        insertedBy: json['inserted_by'] ?? '',
        dateOfCreation:
            json['date_of_creation'] != '' && json['date_of_creation'] != null
                ? DateTime.parse(json['date_of_creation'])
                : DateTime.parse('0001-01-01'),
        stageName: json['stage'] ?? '',
        insertedByName: json['inserted_by_name'] ?? '');
  }
}
