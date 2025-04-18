import 'dart:convert';

import 'package:case_sync/components/basic_ui_component.dart';
import 'package:case_sync/components/task_card.dart';
import 'package:case_sync/models/advocate.dart';
import 'package:case_sync/models/task_item.dart';
import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/screens/interns/editing%20forms/edit_task.dart';
import 'package:case_sync/screens/interns/reassign_task.dart';
import 'package:case_sync/screens/interns/task_info.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:case_sync/utils/slideable_card.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class MyTaskPage extends StatefulWidget {
  final String? highlightedTaskId; // ID from notification to highlight

  const MyTaskPage({
    super.key,
    this.highlightedTaskId,
  });

  @override
  MyTaskPageState createState() => MyTaskPageState();
}

class MyTaskPageState extends State<MyTaskPage> with TickerProviderStateMixin {
  List<TaskItem> assignedToMeList = [];
  List<TaskItem> assignedByMeList = [];
  bool isLoading = true;
  String errorMessage = '';
  Advocate? _userData;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchUserData(); // Start data fetching process
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Fetches user data from shared preferences
  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      _userData = await SharedPrefService.getUser();
      if (_userData == null || _userData!.id.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'User data not found. Cannot load tasks.';
          });
        }
      } else {
        // If user data is found, fetch tasks
        await fetchTasks();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error fetching user data: $e';
        });
      }
      print("Error fetching user data: $e");
    }
  }

  // Fetches the list of tasks for the logged-in intern
  Future<void> fetchTasks() async {
    if (_userData == null || _userData!.id.isEmpty) {
      print("fetchTasks called but _userData is null or ID is empty.");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Cannot fetch tasks without user data.';
        });
      }
      return;
    }

    if (!isLoading && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    final String url = '$baseUrl/advocate_task_list';
    print('Fetching tasks from: $url for intern ID: ${_userData!.id}');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['intern_id'] = _userData!.id;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Task list response status: ${response.statusCode}');
      // print('Task list response body: $responseBody'); // Uncomment for detailed debugging

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        if (parsedResponse['success'] == true &&
            parsedResponse['data'] != null &&
            parsedResponse['data'] is List) {
          final newTaskList = (parsedResponse['data'] as List)
              .map((taskJson) {
                try {
                  return TaskItem.fromJson(taskJson as Map<String, dynamic>);
                } catch (e) {
                  print("Error parsing task item: $taskJson \nError: $e");
                  return null;
                }
              })
              .whereType<TaskItem>()
              .toList();

          List<TaskItem> tempAssignedToMe = [];
          List<TaskItem> tempAssignedByMe = [];

          for (var task in newTaskList) {
            if (task.alloted_to_id == _userData!.id) {
              tempAssignedToMe.add(task);
            }
            if (task.alloted_by_id == _userData!.id) {
              tempAssignedByMe.add(task);
            }
          }

          if (mounted) {
            setState(() {
              assignedToMeList = tempAssignedToMe;
              assignedByMeList = tempAssignedByMe;
              isLoading = false;
              // Update error message based on the currently viewed list or overall?
              // For now, let's base it on the combined list or a general message.
              errorMessage = newTaskList.isEmpty ? 'No tasks available.' : '';
            });
            _attemptScrollToHighlight();
          }
        } else {
          if (mounted) {
            setState(() {
              assignedToMeList = [];
              assignedByMeList = [];
              isLoading = false;
              errorMessage = parsedResponse['message'] as String? ??
                  'Failed to load tasks (Invalid data format or no tasks).';
            });
          }
          print(
              "API Error (Success False or Data Null/Wrong Type): ${parsedResponse['message'] ?? 'Unknown API error'}");
        }
      } else {
        if (mounted) {
          setState(() {
            assignedToMeList = [];
            assignedByMeList = [];
            isLoading = false;
            errorMessage =
                'Failed to fetch tasks (Status Code: ${response.statusCode}).';
          });
        }
        print("HTTP Error ${response.statusCode}: $responseBody");
      }
    } catch (e, stacktrace) {
      print('Error fetching tasks: $e\n$stacktrace');
      if (mounted) {
        setState(() {
          assignedToMeList = [];
          assignedByMeList = [];
          isLoading = false;
          errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  // Schedules scrolling attempt after frame build
  void _attemptScrollToHighlight() {
    // Determine the correct list based on the current tab
    final currentList =
        _tabController.index == 0 ? assignedToMeList : assignedByMeList;

    if (widget.highlightedTaskId != null && currentList.isNotEmpty) {
      final highlightedIndex = currentList
          .indexWhere((task) => task.task_id == widget.highlightedTaskId);

      if (highlightedIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToIndex(highlightedIndex);
          }
        });
      } else {
        print(
            "Highlighted task ID ${widget.highlightedTaskId} not found in the current list.");
      }
    }
  }

  // Helper function to scroll to a specific index in the list
  void _scrollToIndex(int index) {
    if (_scrollController.hasClients) {
      const double itemEstimatedHeight = 280.0; // ADJUST THIS VALUE!
      final scrollOffset = index * itemEstimatedHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetOffset = scrollOffset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print("Attempting to scroll to index $index (offset: $targetOffset)");
    } else {
      print("Scroll controller has no clients, cannot scroll.");
    }
  }

  // Navigates to the ReAssign Task page
  void _navigateToReAssignTask(TaskItem taskItem) async {
    if (_userData == null) {
      _showErrorSnackbar('User data not available.');
      return;
    }
    if (taskItem.task_id.isEmpty) {
      _showErrorSnackbar('Task ID is missing, cannot reassign.');
      return;
    }
  }

  // Helper to show snackbar messages
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleReassign(TaskItem task) async {
    final advocateId = (await SharedPrefService.getUser())!.id;
    if (mounted) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        // isScrollControlled allows the sheet to take up more height,
        // especially needed when the keyboard appears.
        isScrollControlled: true,
        // Make corners rounded to match typical modal style
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // Prevent dismissal by tapping outside if an operation is in progress? (optional)
        // isDismissible: !_isLoading, // You'd need to pass _isLoading state or manage it differently
        backgroundColor: Colors.white,
        // Or your desired sheet background color
        builder: (BuildContext sheetContext) {
          // Pass the necessary IDs to the sheet widget
          return ReAssignTaskSheet(
            taskId: task.task_id,
            advocateId: advocateId,
          );
        },
      );

      // Optional: Handle the result after the sheet is closed
      if (result == true) {
        // Reassignment was successful (sheet popped with 'true')
        print('Task reassignment successful. Refreshing list...');
        fetchTasks();
        // e.g., call a method passed down via constructor or use a state management solution
      } else {
        // Sheet was dismissed without success (e.g., back button, tapped outside)
        print('Reassign task sheet closed without completing.');
      }
    }
  }

  void _showError(String message) {
    SnackBarUtils.showErrorSnackBar(context, message);
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final url = Uri.parse('$baseUrl/delete_task');
      final response = await http.post(url, body: {'task_id': taskId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Remove from the correct list based on the current tab
          setState(() {
            if (_tabController.index == 0) {
              assignedToMeList.removeWhere((task) => task.task_id == taskId);
            } else {
              assignedByMeList.removeWhere((task) => task.task_id == taskId);
            }
            // Also remove from the other list if it exists there (though unlikely with current logic)
            // assignedToMeList.removeWhere((task) => task.task_id == taskId);
            // assignedByMeList.removeWhere((task) => task.task_id == taskId);
          });
          SnackBarUtils.showSuccessSnackBar(
              context, "Task deleted successfully.");
        } else {
          _showError(data['message'] ?? "Failed to delete task.");
        }
      } else {
        _showError("Failed to delete task.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  Future<void> _handleEdit(TaskItem task) async {
    print("Edit task: ${task.instruction}");
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTaskScreen(taskDetails: TaskItem.toJson(task)),
      ),
    );
    if (result) {
      fetchTasks();
    }
  }

  void _handleDelete(TaskItem task) {
    print("Delete task: ${task.instruction}");
    _deleteTask(task.task_id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          tooltip: 'Back',
        ),
        title: const Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: [
            Tab(
                text: (assignedByMeList.isEmpty && assignedToMeList.isEmpty)
                    ? 'Assigned to Me'
                    : 'Assigned to Me (${assignedToMeList.length})'),
            Tab(
                text: (assignedByMeList.isEmpty && assignedToMeList.isEmpty)
                    ? 'Assigned by Me'
                    : 'Assigned by Me (${assignedByMeList.length})'),
          ],
          onTap: (index) {
            // Just trigger a rebuild, data is already filtered
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : TabBarView(
              controller: _tabController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Tab 1: Tasks assigned to me
                LiquidPullToRefresh(
                  onRefresh: fetchTasks,
                  backgroundColor: Colors.black,
                  color: Colors.transparent,
                  showChildOpacityTransition: false,
                  child: _buildTaskList(assignedToMeList),
                ),
                // Tab 2: Tasks assigned by me
                LiquidPullToRefresh(
                  onRefresh: fetchTasks,
                  backgroundColor: Colors.black,
                  color: Colors.transparent,
                  showChildOpacityTransition: false,
                  child: _buildTaskList(assignedByMeList),
                ),
              ],
            ),
    );
  }

  // Build task list for the current tab
  Widget _buildTaskList(List<TaskItem> taskList) {
    if (taskList.isNotEmpty) {
      return ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure list is always scrollable
        controller: _scrollController, // Attach scroll controller
        itemCount: taskList.length,
        padding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 8.0), // Adjust padding
        itemBuilder: (context, index) {
          final taskItem = taskList[index];
          final bool isHighlighted =
              taskItem.task_id == widget.highlightedTaskId;

          // Condition to show the "NEW" tag
          final bool shouldShowNewTag =
              taskItem.task_id == widget.highlightedTaskId;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: SlideableCard(
              onEdit: () => _handleEdit(taskItem),
              onDelete: () => _handleDelete(taskItem),
              canReassign: true,
              onReassign: () => _handleReassign(taskItem),
              name: 'this task',
              child: TaskCard(
                key: ValueKey(taskItem.task_id), // Important for list updates
                taskItem: taskItem,
                isHighlighted: isHighlighted,
                showNewTaskTag: shouldShowNewTag, // Pass the calculated flag
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskInfoPage(taskId: taskItem.task_id),
                    ),
                  );
                  fetchTasks();
                },
              ),
            ),
          );
        },
      );
    } else {
      // Display error message or "No tasks" message
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : 'No tasks available.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

// --- AnimatedListTile Widget (Keep as is) ---
class AnimatedListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final bool enabled;
  final VoidCallback? onTap;

  const AnimatedListTile({
    super.key,
    required this.leading,
    required this.title,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = enabled
        ? Theme.of(context).listTileTheme.iconColor ??
            Theme.of(context).iconTheme.color ??
            Colors.black
        : Theme.of(context).disabledColor;
    final TextStyle effectiveTextStyle = enabled
        ? Theme.of(context).listTileTheme.titleTextStyle ??
            Theme.of(context).textTheme.titleMedium ??
            const TextStyle()
        : Theme.of(context)
                .listTileTheme
                .titleTextStyle
                ?.copyWith(color: Theme.of(context).disabledColor) ??
            Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).disabledColor) ??
            TextStyle(color: Theme.of(context).disabledColor);

    return ListTile(
      leading: IconTheme.merge(
        data: IconThemeData(color: effectiveColor),
        child: leading,
      ),
      title: DefaultTextStyle.merge(
        style: effectiveTextStyle,
        child: title,
      ),
      enabled: enabled,
      onTap: onTap,
      splashColor: Theme.of(context).splashColor,
      hoverColor: Theme.of(context).hoverColor,
    );
  }
}
