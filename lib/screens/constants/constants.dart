import 'package:case_sync/services/api_helper.dart';

const List<String> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

// Use the ApiHelper.baseUrl getter to access the current flavor's base URL
String get baseUrl => ApiHelper.baseUrl;

// Previous hardcoded URLs:
// Test: "https://pragmanxt.com/case_sync_test/services/admin/v1/index.php"
// Production: "https://pragmanxt.com/case_sync_pro/services/admin/v1/index.php"
