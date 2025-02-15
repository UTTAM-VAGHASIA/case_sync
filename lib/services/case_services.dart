import 'package:intl/intl.dart';

import '../models/case_list.dart';
import '../services/api_service.dart'; // Ensure correct import path for your API service

final Map<String, Map<String, List<CaseListData>>> caseData = {};
final List<String> years = []; // New variable to store distinct years

Future<int> populateCaseData() async {
  try {
    // Fetch data from API
    final List<CaseListData> cases = await CaseApiService.fetchCaseList();

    if (cases.isEmpty) {
      return 0;
    }

    // Clear existing data to avoid duplication
    caseData.clear();
    years.clear(); // Clear years list to avoid duplication

    for (var caseItem in cases) {
      // Extract year and month from srDate
      String year = caseItem.dateOfFiling.year.toString();
      String month =
          DateFormat('MMMM').format(caseItem.dateOfFiling); // Full month name

      // Add the year to the years list if not already present
      if (!years.contains(year)) {
        years.add(year);
      }

      // Initialize nested map for the year if it doesn't exist
      if (!caseData.containsKey(year)) {
        caseData[year] = {};
      }

      // Initialize list for the month if it doesn't exist
      if (!caseData[year]!.containsKey(month)) {
        caseData[year]![month] = [];
      }

      // Add the case to the appropriate year and month
      caseData[year]![month]!.add(caseItem);
    }

    // Sort the years list in ascending order
    years.sort();

    print('Case data populated successfully.');
    print(cases.length);
    return cases.length;
  } catch (e) {
    print('Error populating case data: $e');
  }
  return 0;
}

List<CaseListData> getCaseDataForMonth(String year, String month) {
  return caseData[year]?[month] ?? [];
}
