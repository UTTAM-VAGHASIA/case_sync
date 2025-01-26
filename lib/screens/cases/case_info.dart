import 'dart:convert';

import 'package:case_sync/screens/cases/view_docs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CaseInfoPage extends StatefulWidget {
  final String caseId;
  final String caseNo;

  const CaseInfoPage({super.key, required this.caseId, required this.caseNo});

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
              'case_no': caseData['case_no'],
              'year': caseData['year'],
              'case_type': caseData['case_type'],
              'stage_name': caseData['stage_name'],
              'Company Name': caseData['company_name'],
              'advocate_name': caseData['advocate_name'],
              'applicant': caseData['applicant'],
              'opp_name': caseData['opp_name'],
              'court_name': caseData['court_name'],
              'city_name': caseData['city_name'],
              'next_date': parseDate(caseData['next_date']),
              'next_stage': caseData['next_stage'],
              'sr_date': parseDate(caseData['sr_date']),
              'complainant_advocate': caseData['complainant_advocate'],
              'respondent_advocate': caseData['respondent_advocate'],
              'date_of_filing': parseDate(caseData['date_of_filing']),
              'case_counter': caseData['case_counter'],
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
                          'Case Year': _caseDetails['year'],
                          'Case Type': _caseDetails['case_type'],
                          'Current Stage': _caseDetails['stage_name'],
                          'Next Stage': _caseDetails['next_stage'],
                          'Company Name': _caseDetails['company_name'],
                          'Plaintiff Name': _caseDetails['applicant'],
                          'Opponent Name': _caseDetails['opp_name'],
                          'Complainant Advocate':
                              _caseDetails['complainant_advocate'],
                          'Respondent Advocate':
                              _caseDetails['respondent_advocate'],
                          'Court': _caseDetails['court_name'],
                          'City': _caseDetails['city_name'],
                          'Summon Date': _caseDetails['sr_date'] is DateTime
                              ? DateFormat('dd-MM-yyyy')
                                  .format(_caseDetails['sr_date'])
                              : _caseDetails['sr_date'],
                          'Next Date': _caseDetails['nextDate'] is DateTime
                              ? DateFormat('dd-MM-yyyy')
                                  .format(_caseDetails['nextDate'])
                              : _caseDetails['nextDate'],
                          'Date Of Filing':
                              _caseDetails['date_of_filing'] is DateTime
                                  ? DateFormat('dd-MM-yyyy')
                                      .format(_caseDetails['date_of_filing'])
                                  : _caseDetails['date_of_filing'],
                          'Case Counter': _caseDetails['case_counter'],
                          'Handled By': _caseDetails['handle_by'],
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
              builder: (context) => ViewDocs(
                caseId: widget.caseId,
                caseNo: widget.caseNo,
              ),
            ),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.visibility),
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
                displayValue = '-';
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
