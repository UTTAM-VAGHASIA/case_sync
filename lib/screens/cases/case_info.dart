import 'dart:convert';

import 'package:case_sync/screens/cases/view_docs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CaseInfoPage extends StatefulWidget {
  final String caseId;
  final String caseNo;

  const CaseInfoPage({Key? key, required this.caseId, required this.caseNo})
      : super(key: key);

  @override
  _CaseInfoPageState createState() => _CaseInfoPageState();
}

class _CaseInfoPageState extends State<CaseInfoPage> {
  bool _isLoading = true;
  Map<String, dynamic> _caseDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchCaseInfo().then((_) {
      if (_caseDetails['case_no'] != null &&
          _caseDetails['case_no']!.isNotEmpty) {}
    });
  }

  Future<void> _fetchCaseInfo() async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_info');
      final response = await http.post(url, body: {'case_id': widget.caseId});
      print("Case Id: ${widget.caseId}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print("Case Info API Response: $data");
        }
        if (data['success'] == true && data['data'].isNotEmpty) {
          setState(() {
            final caseData = data['data'][0];

            DateTime? parseDate(String? date) {
              if (date == null || date.isEmpty || date == '0000-00-00') {
                return null;
              }
              try {
                return DateTime.parse(date);
              } catch (_) {
                return null;
              }
            }

            _caseDetails = {
              'case_no': caseData['case_no'] ?? 'No data found',
              'year': caseData['year'] ?? 'No data found',
              'type': caseData['case_type'] ?? 'No data found',
              'Current Stage': caseData['stage_name'] ?? 'No data found',
              'Next Stage': caseData['next_stage'] ?? 'No data found',
              'applicant': caseData['applicant'] ?? 'No data found',
              'opponent': caseData['opp_name'] ?? 'No data found',
              'court': caseData['court_name'] ?? 'No data found',
              'location': caseData['city_name'] ?? 'No data found',
              'summonDate': parseDate(caseData['sr_date']) ?? 'No data found',
              'nextDate': parseDate(caseData['next_date']) ?? 'No data found',
              'remark': 'No remarks available.', // Placeholder
            };
          });
        } else {
          _showError("No data found for the given case.");
        }
      } else {
        _showError("Failed to fetch case details.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Case No: ${widget.caseNo}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : _caseDetails.isEmpty || _caseDetails['case_no'] == 'No data found'
              ? const Center(
                  child: Text(
                    'No data found',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailsCard(
                        title: 'Case Details',
                        details: {
                          'Case Year': _caseDetails['year']!,
                          'Case Type': _caseDetails['type']!,
                          'Current Stage': _caseDetails['Current Stage']!,
                          'Next Stage': _caseDetails['Next Stage']!,
                          'Plaintiff Name': _caseDetails['applicant']!,
                          'Opponent Name': _caseDetails['opponent']!,
                          'Court': _caseDetails['court']!,
                          'City': _caseDetails['location']!,
                          'Summon Date': _caseDetails['summonDate'] is DateTime
                              ? DateFormat('dd-MM-yyyy')
                                  .format(_caseDetails['summonDate'])
                              : _caseDetails['summonDate'],
                          'Next Date': _caseDetails['nextDate'] is DateTime
                              ? DateFormat('dd-MM-yyyy')
                                  .format(_caseDetails['nextDate'])
                              : _caseDetails['nextDate'],
                        },
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDocs(caseId: widget.caseId),
            ),
          );
        },
        child: const Icon(Icons.visibility),
        backgroundColor: Colors.black,
      ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required Map<String, dynamic> details,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...details.entries.map((entry) {
              String displayValue;
              if (entry.value is DateTime) {
                displayValue = DateFormat('dd-MM-yyyy').format(entry.value);
              } else if (entry.value == null ||
                  entry.value.toString().isEmpty) {
                displayValue = 'No data found';
              } else {
                displayValue = entry.value.toString();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        displayValue,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
