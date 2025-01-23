import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ViewDocs extends StatefulWidget {
  final String caseId;

  const ViewDocs({Key? key, required this.caseId}) : super(key: key);

  @override
  State<ViewDocs> createState() => _ViewDocsState();
}

class _ViewDocsState extends State<ViewDocs> {
  final List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      // First API call
      final caseInfoUrl = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_info');
      final caseInfoResponse = await http.post(
        caseInfoUrl,
        body: {'case_id': widget.caseId},
      );

      if (caseInfoResponse.statusCode == 200) {
        final caseInfoData = jsonDecode(caseInfoResponse.body);
        if (caseInfoData['success'] == true &&
            caseInfoData['data'].isNotEmpty) {
          final documentUrl = caseInfoData['data'][0]['docs'] ?? '';
          _documents.add({
            'id': 'N/A',
            'docs': documentUrl,
            'added_by': 'N/A',
            'user_type': 'N/A',
            'date_time': 'N/A',
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch case info. Status code: ${caseInfoResponse.statusCode}';
        });
        return;
      }

      // Second API call
      final caseDocumentsUrl = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/get_case_documents');
      final caseDocumentsResponse = await http.post(
        caseDocumentsUrl,
        body: {'case_no': widget.caseId},
      );

      if (caseDocumentsResponse.statusCode == 200) {
        final caseDocumentsData = jsonDecode(caseDocumentsResponse.body);
        if (caseDocumentsData['success'] == true &&
            caseDocumentsData['data'].isNotEmpty) {
          final documents = caseDocumentsData['data'] as List<dynamic>;
          _documents.addAll(documents.cast<Map<String, dynamic>>());
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch additional documents. Status code: ${caseDocumentsResponse.statusCode}';
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _openDocument(String url) async {
    final encodedUrl = Uri.encodeFull(url);
    if (await canLaunch(encodedUrl)) {
      await launch(encodedUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Could not open the document. Please check if you have the required viewer installed.'),
          action: SnackBarAction(
            label: 'Copy Link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
          ),
        ),
      );
    }
  }

  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif');
  }

  bool _isDocumentUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.docx') || lowerUrl.endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Documents'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    final docUrl = doc['docs'];
                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document ID: ${doc['id']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Text('Added By: ${doc['added_by']}'),
                            const SizedBox(height: 8.0),
                            Text('User Type: ${doc['user_type']}'),
                            const SizedBox(height: 8.0),
                            Text('Date Time: ${doc['date_time']}'),
                            const SizedBox(height: 8.0),
                            _isImageUrl(docUrl)
                                ? GestureDetector(
                                    onTap: () => _openDocument(docUrl),
                                    child: Image.network(
                                      docUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Text(
                                          'Error loading image',
                                          style: TextStyle(color: Colors.red),
                                        );
                                      },
                                    ),
                                  )
                                : _isDocumentUrl(docUrl)
                                    ? ElevatedButton(
                                        onPressed: () => _openDocument(docUrl),
                                        child: const Text('Open Document'),
                                      )
                                    : GestureDetector(
                                        onTap: () => _openDocument(docUrl),
                                        child: Text(
                                          docUrl,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
