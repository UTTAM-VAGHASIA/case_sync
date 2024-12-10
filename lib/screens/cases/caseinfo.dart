import 'package:flutter/material.dart';

class CaseInfoPage extends StatelessWidget {
  final Map<String, String> caseData;

  const CaseInfoPage({super.key, required this.caseData});

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
          'Case No. ${caseData['caseId'] ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailsCard(
              title: 'Case Details',
              details: {
                'Case Year': caseData['year'] ?? 'N/A',
                'Case Type': caseData['type'] ?? 'N/A',
                'Company': caseData['company'] ?? 'N/A',
                'Plaintiff Name': caseData['plaintiff'] ?? 'N/A',
                'Court': caseData['court'] ?? 'N/A',
                'City': caseData['location'] ?? 'N/A',
                'Summon Date': caseData['summonDate'] ?? 'N/A',
              },
            ),
            const SizedBox(height: 16),
            _buildDetailsCard(
              title: 'Intern Status',
              details: {
                'Assigned By': caseData['assignedBy'] ?? 'N/A',
                'Assigned To': caseData['assignedTo'] ?? 'N/A',
                'Assigned Date': caseData['assignedDate'] ?? 'N/A',
              },
            ),
            const SizedBox(height: 16),
            _buildDetailsCard(
              title: 'Remark Log',
              details: {
                'Remark': caseData['remark'] ?? 'No remarks available.',
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
            }).toList(),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CaseInfoPage(
      caseData: {
        'caseId': 'C1234',
        'year': '2001',
        'type': 'Criminal',
        'company': 'Boeing',
        'plaintiff': 'Kelly Ortberg',
        'court': 'Supreme',
        'location': 'Delhi',
        'summonDate': '09/11/2001',
        'assignedBy': 'Advocate',
        'assignedTo': 'Intern',
        'assignedDate': '11/09/2001',
        'remark': 'Initial hearing scheduled.',
      },
    ),
  ));
}
