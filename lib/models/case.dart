class Case {
  final String id;
  final String caseNo;
  final String handleBy;
  final String applicant;
  final String opponent;
  final String courtName;
  final DateTime srDate;
  final String cityName;
  final String caseType;
  final String caseCounter;

  Case({
    required this.id,
    required this.caseNo,
    required this.handleBy,
    required this.applicant,
    required this.opponent,
    required this.courtName,
    required this.srDate,
    required this.cityName,
    required this.caseType,
    required this.caseCounter,
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id'],
      caseNo: json['case_no'] ?? '',
      handleBy: json['handle_by'] ?? '',
      applicant: json['applicant'] ?? '',
      opponent: json['opp_name'] ?? '',
      courtName: json['court_name'] ?? '',
      srDate: json['sr_date'] != '' && json['sr_date'].isNotEmpty
          ? DateTime.parse(json['sr_date'])
          : DateTime.parse('0001-01-01'),
      cityName: json['city_name'] ?? '',
      caseType: json['case_type'] ?? '',
      caseCounter: json['case_counter'] ?? '',
    );
  }
}
