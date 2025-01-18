import 'dart:convert';
import 'package:case_sync/screens/cases/view_docs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CaseInfoPage extends StatefulWidget {
  final String caseId;

  const CaseInfoPage({Key? key, required this.caseId}) : super(key: key);

  @override
  _CaseInfoPageState createState() => _CaseInfoPageState();
}

class _CaseInfoPageState extends State<CaseInfoPage> {
  bool _isLoading = true;
  Map<String, String> _caseDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchCaseInfo().then((_) {
      if (_caseDetails['case_no'] != null &&
          _caseDetails['case_no']!.isNotEmpty) {
        _fetchAssignedInfo();
      }
    });
  }

  Future<void> _fetchCaseInfo() async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_info');
      final response = await http.post(url, body: {'case_id': widget.caseId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print("Case Info API Response: $data");
        }
        if (data['success'] == true && data['data'].isNotEmpty) {
          setState(() {
            final caseData = data['data'][0];
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
              'summonDate': caseData['sr_date'] ?? 'No data found',
              'assignedBy': 'Fetching...', // Placeholder
              'assignedTo': 'Fetching...', // Placeholder
              'nextDate': caseData['next_date'] ?? 'No data found',
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

  Future<void> _fetchAssignedInfo() async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_task');
      final response = await http.post(
        url,
        body: {'case_no': _caseDetails['case_no'] ?? ''},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (kDebugMode) {
          print("Assigned Info API Response: $data");
        }

        if (data['success'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
          setState(() {
            final assignedData = data['data'][0]; // Get the first task object
            _caseDetails['assignedBy'] =
                assignedData['alloted_by_name'] ?? 'No data found';
            _caseDetails['assignedTo'] =
                assignedData['alloted_to_name'] ?? 'No data found';
            _caseDetails['remark'] =
                assignedData['remarks'] ?? 'No remarks available.';
          });
        } else {
          setState(() {
            _caseDetails['assignedBy'] = 'No data found';
            _caseDetails['assignedTo'] = 'No data found';
            _caseDetails['remark'] = 'No remarks available.';
          });
          _showError("No data found for the assigned info.");
        }
      } else {
        _showError(
            "Failed to fetch assigned info. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      _showError("An error occurred while fetching assigned info: $e");
      setState(() {
        _caseDetails['assignedBy'] = 'Error';
        _caseDetails['assignedTo'] = 'Error';
        _caseDetails['remark'] = 'Error retrieving remarks.';
      });
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
          'Case No. ${_caseDetails['case_no'] ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          'Summon Date': _caseDetails['summonDate']!,
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDetailsCard(
                        title: 'Intern Status',
                        details: {
                          'Assigned By': _caseDetails['assignedBy']!,
                          'Assigned To': _caseDetails['assignedTo']!,
                          'Next Date': _caseDetails['nextDate']!,
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDetailsCard(
                        title: 'Remark Log',
                        details: {
                          'Remark': _caseDetails['remark']!,
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
    required Map<String, String> details,
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
                        entry.value,
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
