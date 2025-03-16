import 'dart:convert';

import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../components/basic_ui_component.dart';
import '../../../models/proceed_history_list.dart';
import '../../../utils/update_stage_modal.dart';
import '../../constants/constants.dart';
import 'proceed_history_item.dart';

class CaseHistoryPage extends StatefulWidget {
  final String caseId;
  final String caseNo;

  const CaseHistoryPage(
      {super.key, required this.caseId, required this.caseNo});

  @override
  State<CaseHistoryPage> createState() => _CaseHistoryPageState();
}

class _CaseHistoryPageState extends State<CaseHistoryPage>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  List<ProceedHistoryListData> proceedingList = [];
  List<Map<String, dynamic>> stageList = [];
  String? selectedStage;
  late String advocateId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchProceedings();
    _fetchStageList();
  }

  Future<void> fetchProceedings() async {
    advocateId = (await SharedPrefService.getUser())!.id;
    if (kDebugMode) {
      print("Fetching Proceedings...");
    }
    try {
      final url = Uri.parse('$baseUrl/proceed_history');
      final request = http.MultipartRequest('POST', url);
      // Add the multipart data
      request.fields['case_id'] = widget.caseId;
      if (kDebugMode) {
        print(request.fields['case_id']);
      }

      // Send the request and get the response
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          setState(() {
            if (data['data'] is List) {
              proceedingList = (data['data'] as List)
                  .map((item) => ProceedHistoryListData.fromJson(item))
                  .toList();
              if (kDebugMode) {
                print(proceedingList[0].id); // change to [0]
              }

              if (kDebugMode) {
                print(proceedingList[0].stage); // change to [0]
              }
              final currentStageName = proceedingList[0].stage; // change to [0]

              final matchingStage = stageList.firstWhere(
                // change to firstWhere
                (stage) => stage['stage'] == currentStageName,
                orElse: () => <String, dynamic>{},
              );

              if (kDebugMode) {
                print(matchingStage['id']);
              }

              // Check if matchingStage is not empty
              if (matchingStage.isNotEmpty) {
                final currentStageIndex = stageList.indexOf(matchingStage);

                // // If the current stage is the last in the list, don't increment the stage
                // if (currentStageIndex < stageList.length - 1) {
                //   selectedStage =
                //       (int.parse(matchingStage['id']) + 1).toString();
                // } else {
                //   selectedStage = matchingStage[
                //       'id']; // Keep the current stage if it's the last one
                // }

                selectedStage = (currentStageIndex).toString();
              } else {
                selectedStage = null;
              }

              if (kDebugMode) {
                print(selectedStage);
              }
            } else {
              proceedingList =
                  []; // Assign an empty list if the data is not a list
            }
          });
        } else {
          _showError(data['message'] ?? "No tasks found.");
        }
      } else {
        _showError("Failed to fetch tasks. Please try again.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print("Fetched Proceedings");
      }
    }
  }

  Future<void> _deleteProceeding(String proceedingId) async {
    try {
      print(proceedingId);
      var scaffoldMessenger = ScaffoldMessenger.of(context);
      final url = Uri.parse('$baseUrl/proceed_case_delete');
      final request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({"proceed_id": proceedingId});
      print(request.fields['data']);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['success'] == true) {
        setState(() {
          proceedingList
              .removeWhere((proceeding) => proceeding.id == proceedingId);
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Task deleted successfully.")),
        );
      } else {
        _showError(data['message'] ?? "Failed to delete task.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _fetchStageList() async {
    try {
      if (kDebugMode) {
        print("Fetching stage list...");
      }
      final url = Uri.parse('$baseUrl/stage_list');
      var request = http.MultipartRequest("POST", url);
      request.fields['case_id'] = widget.caseId;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['success'] == true) {
        setState(() {
          stageList = List<Map<String, dynamic>>.from(data['data']);
          if (kDebugMode) {
            print("Stage List: $stageList");
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching stage list: $e");
      }
    }
    if (kDebugMode) {
      print("Fetched stage list");
    }
  }

  Future<void> _handleEdit(ProceedHistoryListData proceeding) async {
    var scaffoldMessenger = ScaffoldMessenger.of(context);
    if (kDebugMode) {
      print("Edit task: ${proceeding.stage}");
    }

    if (advocateId == proceeding.insertedBy &&
        (proceeding.insertedBy != null || proceeding.insertedBy != "")) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return UpdateStageModal(
            isEditing: true,
            proceedingId: proceeding.id,
            caseId: proceeding.caseId,
            initialDate: (proceeding.nextDate != DateTime.parse("0001-01-01"))
                ? proceeding.nextDate
                : DateTime.now(),
            initialStage: proceeding.nextStage,
            stageList: stageList,
            insertedBy: proceeding.insertedBy,
          );
        },
      );

      fetchProceedings();
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
              "You don't have permission to edit this stage as the proceeding detail is added by a different user."),
        ),
      );
    }
  }

  void _handleDelete(ProceedHistoryListData proceeding) {
    var scaffoldMessenger = ScaffoldMessenger.of(context);
    if (kDebugMode) {
      print("Delete task: ${proceeding.stage}");
    }
    if (advocateId == proceeding.insertedBy &&
        (proceeding.insertedBy != null || proceeding.insertedBy != "")) {
      _deleteProceeding(proceeding.id);
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
              "You don't have permission to edit this stage as the proceeding detail is added by a different user."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: Colors.black,
                width: 1,
              )),
          elevation: 3,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                  color: Colors.black,
                ))
              : proceedingList.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: Text(
                                "No Proceeding Info found for this case.")),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            fetchProceedings();
                            _fetchStageList();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : Padding(
                      padding: EdgeInsets.all(16.0),
                      child: RefreshIndicator(
                        color: Colors.black,
                        onRefresh: () async {
                          fetchProceedings();
                        },
                        child: ListView.builder(
                          itemCount: proceedingList.length,
                          itemBuilder: (context, index) {
                            return ProceedHistoryItem(
                              proceeding: proceedingList[index],
                              onEdit: () async =>
                                  await _handleEdit(proceedingList[index]),
                              onDelete: () =>
                                  _handleDelete(proceedingList[index]),
                            );
                          },
                        ),
                      ),
                    ),
        ),
      ),
      floatingActionButton: ElevatedButton(
        style: AppTheme.elevatedButtonStyle, // Use the style from AppTheme
        onPressed: () async {
          HapticFeedback.mediumImpact();
          _showUpdateStageModal();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Proceed the Case",
              style: AppTheme
                  .buttonTextStyle, // Use the button text style from AppTheme
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_circle_right_outlined,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateStageModal() async {
    print("Selected Stage: $selectedStage");
    // Pass stage ID, not name
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        if (proceedingList.isEmpty) {
          return UpdateStageModal(
            caseId: widget.caseId,
            initialDate: DateTime.now(),
            initialStage: null,
            stageList: stageList,
          );
        }
        return UpdateStageModal(
          caseId: widget.caseId,
          initialDate: (proceedingList[0].nextDate !=
                  DateTime.parse("0001-01-01")) // change to [0]
              ? proceedingList[0].nextDate // change to [0]
              : DateTime.now(),
          initialStage: selectedStage,
          stageList: stageList,
        );
      },
    );

    fetchProceedings();
    await _fetchStageList();
  }
}
