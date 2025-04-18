import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../../utils/snackbar_utils.dart';
import '../../constants/constants.dart';
import 'document_card.dart';

class ViewDocsPage extends StatefulWidget {
  final String caseId;
  final String caseNo;

  const ViewDocsPage({super.key, required this.caseId, required this.caseNo});

  @override
  State<ViewDocsPage> createState() => _ViewDocsPageState();
}

class _ViewDocsPageState extends State<ViewDocsPage>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    _documents.clear();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_case_documents'),
        body: {'case_no': widget.caseId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'].isNotEmpty) {
          if (!mounted) return;
          setState(() {
            // Parse the fetched data
            final fetchedDocuments =
                List<Map<String, dynamic>>.from(data['data']);

            // Remove duplicates by ensuring unique `file_id`
            final existingFileIds =
                _documents.map((doc) => doc['file_id']).toSet();
            final filteredDocuments = fetchedDocuments.where((doc) {
              return !existingFileIds.contains(doc['file_id']);
            }).toList();

            // Add only unique documents
            _documents.addAll(filteredDocuments);
            if (kDebugMode) {
              print("Filtered unique documents: $_documents");
            }
          });
        } else {
          if (!mounted) return;
          SnackBarUtils.showInfoSnackBar(context, 'No documents available.');
          setState(() {
            _documents.clear();
          });
        }
      } else {
        if (!mounted) return;
        SnackBarUtils.showErrorSnackBar(
          context,
          'Failed to fetch documents. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showErrorSnackBar(context, 'An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.black))
          else
            LiquidPullToRefresh(
              backgroundColor: Colors.black,
              color: Colors.transparent,
              showChildOpacityTransition: false,
              onRefresh: () async {
                setState(() {
                  _fetchDocuments();
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) => DocumentCard(
                      doc: _documents[index],
                      caseNo: widget.caseNo,
                      onEditSuccess: _fetchDocuments,
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
