final Map<String, Map<String, List<Map<String, String>>>> caseData = {
  '2024': {
    'January': [
      {'caseId': '#Case202401', 'plaintiff': 'John Doe', 'location': 'Court A'},
      {'caseId': '#Case202402', 'plaintiff': 'Jane Smith', 'location': 'Court B'},
    ],
    'February': [
      {'caseId': '#Case202403', 'plaintiff': 'John Smith', 'location': 'Court C'},
    ],
  },
  '2023': {
    'January': [
      {'caseId': '#Case202301', 'plaintiff': 'Alan Brown', 'location': 'Court D'},
    ],
    'February': [
      {'caseId': '#Case202302', 'plaintiff': 'Linda White', 'location': 'Court E'},
    ],
  },
};

List<Map<String, String>> getCaseDataForMonth(String year, String month) {
  return caseData[year]?[month] ?? [];
}

final Map<String, Map<String, List<Map<String, String>>>> AssignedCaseData = {
  '2024': {
    'January': [
      {'caseId': '#Case202401', 'plaintiff': 'John Doe', 'assignedTo': 'Intern 1'},
      {'caseId': '#Case202402', 'plaintiff': 'Jane Smith', 'assignedTo': 'Intern 2'},
    ],
    'February': [
      {'caseId': '#Case202403', 'plaintiff': 'John Smith', 'assignedTo': 'Intern 2'},
    ],
  },
  '2023': {
    'January': [
      {'caseId': '#Case202301', 'plaintiff': 'Alan Brown', 'assignedTo': 'Intern 3'},
    ],
    'February': [
      {'caseId': '#Case202302', 'plaintiff': 'Linda White', 'assignedTo': 'Intern 3'},
    ],
  },
};

List<Map<String, String>> getAssignedCaseDataForMonth(String year, String month) {
  return AssignedCaseData[year]?[month] ?? [];
}