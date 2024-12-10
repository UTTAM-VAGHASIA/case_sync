class Case {
  final String id;
  final String caseNo;
  final int year;
  final String caseType;
  final String stage;
  final String companyId;
  final String handleBy;
  final String docs;
  final String applicant;
  final String opponent;
  final String courtName;
  final String cityId;
  final DateTime? nextDate;
  final String nextStage;
  final DateTime srDate;
  final String status;
  final String cityName;

  Case({
    required this.id,
    required this.caseNo,
    required this.year,
    required this.caseType,
    required this.stage,
    required this.companyId,
    required this.handleBy,
    required this.docs,
    required this.applicant,
    required this.opponent,
    required this.courtName,
    required this.cityId,
    this.nextDate,
    required this.nextStage,
    required this.srDate,
    required this.status,
    required this.cityName,
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id'] ?? '',
      caseNo: json['case_no'] ?? '',
      year: int.parse(json['year']),
      caseType: json['case_type'] ?? '',
      stage: json['stage'] ?? '',
      companyId: json['company_id'] ?? '',
      handleBy: json['handle_by'] ?? '',
      docs: json['docs'] ?? '',
      applicant: json['applicant'] ?? '',
      opponent: json['opp_name'] ?? '',
      courtName: json['court_name'] ?? '',
      cityId: json['city_id'] ?? '',
      nextDate: json['next_date'] != null && json['next_date'].isNotEmpty
          ? DateTime.tryParse(json['next_date'])
          : null,
      nextStage: json['next_stage'] ?? '',
      srDate: DateTime.parse(json['sr_date']),
      status: json['status'] ?? '',
      cityName: json['city_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_no': caseNo,
      'year': year.toString(),
      'case_type': caseType,
      'stage': stage,
      'company_id': companyId,
      'handle_by': handleBy,
      'docs': docs,
      'applicant': applicant,
      'opp_name': opponent,
      'court_name': courtName,
      'city_id': cityId,
      'next_date': nextDate?.toIso8601String() ?? '',
      'next_stage': nextStage,
      'sr_date': srDate.toIso8601String(),
      'status': status,
      'city_name': cityName,
    };
  }
}
