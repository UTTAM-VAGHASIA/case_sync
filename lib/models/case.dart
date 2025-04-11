class Case {
  final String id;
  final String caseNo;
  final String year;
  final String caseType;
  final String stage;
  final String company;
  final String handleBy;
  final String applicant;
  final String opponent;
  final String courtName;
  final String cityName;
  final DateTime nextDate;
  final DateTime srDate;
  final String complainantAdvocate;
  final String respondentAdvocate;
  final DateTime dateOfFiling;
  final String caseCounter;

  Case({
    required this.id,
    required this.caseNo,
    required this.year,
    required this.caseType,
    required this.stage,
    required this.company,
    required this.handleBy,
    required this.applicant,
    required this.opponent,
    required this.courtName,
    required this.cityName,
    required this.nextDate,
    required this.srDate,
    required this.complainantAdvocate,
    required this.respondentAdvocate,
    required this.dateOfFiling,
    required this.caseCounter,
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id'] ?? '',
      caseNo: json['case_no'] ?? '',
      year: json['year'] ?? '',
      caseType: json['case_type'] ?? '',
      stage: json['stage_name'] ?? '',
      company: json['company_name'] ?? '',
      handleBy: json['advocate_name'] ?? '',
      applicant: json['applicant'] ?? '',
      opponent: json['opp_name'] ?? '',
      courtName: json['court_name'] ?? '',
      cityName: json['city_name'] ?? '',
      nextDate: (json['next_date'] == null ||
              json['next_date'].toString() == '0000-00-00' ||
              json['next_date'].toString().isEmpty)
          ? DateTime.parse('0001-01-01')
          : DateTime.parse(json['next_date']),
      srDate: (json['sr_date'] == null ||
              json['sr_date'].toString() == '0000-00-00' ||
              json['sr_date'].toString().isEmpty)
          ? DateTime.parse('0001-01-01')
          : DateTime.parse(json['sr_date']),
      complainantAdvocate: json['complainant_advocate'] ?? '',
      respondentAdvocate: json['respondent_advocate'] ?? '',
      dateOfFiling: (json['date_of_filing'] == null ||
              json['date_of_filing'].toString() == '0000-00-00' ||
              json['date_of_filing'].toString().isEmpty)
          ? DateTime.parse('0001-01-01')
          : DateTime.parse(json['date_of_filing']),
      caseCounter: json['case_counter'] ?? '',
    );
  }
}
