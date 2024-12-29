import 'dart:convert';

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
    _fetchCaseInfo();
  }

  Future<void> _fetchCaseInfo() async {
    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_info');
      final response = await http.post(url, body: {
        'case_id': widget.caseId,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print(data);
        }
        if (data['success'] == true && data['data'].isNotEmpty) {
          setState(() {
            _caseDetails = {
              'case_no': data['data'][0]['case_no'] ?? 'N/A',
              'year': data['data'][0]['year'] ?? 'N/A',
              'type': data['data'][0]['case_type'] ?? 'N/A',
              'Current Stage': data['data'][0]['stage'] ?? 'N/A',
              'applicant': data['data'][0]['applicant'] ?? 'N/A',
              'opponent': data['data'][0]['opp_name'] ?? 'N/A',
              'court': data['data'][0]['court'] ?? 'N/A',
              'location': data['data'][0]['name'] ?? 'N/A',
              'summonDate': data['data'][0]['sr_date'] ?? 'N/A',
              'assignedBy': 'Unknown', // Adjust as needed
              'assignedTo': 'Unknown', // Adjust as needed
              'assignedDate': 'Unknown', // Adjust as needed
              'remark': 'No remarks available.', // Adjust as needed
            };
          });
        } else {
          _showError("Case details not found.");
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
          'Case No. ${_caseDetails['case_no'] ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      'Current Stage': _caseDetails['stage'],
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
                      'Assigned Date': _caseDetails['assignedDate']!,
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
