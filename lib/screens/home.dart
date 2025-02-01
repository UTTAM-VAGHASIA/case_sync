import 'dart:convert';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:case_sync/models/advocate.dart';
import 'package:case_sync/services/case_services.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../models/case.dart';
import '../utils/constants.dart';
import 'appbar/notification_drawer.dart';
import 'appbar/settings_drawer.dart';
import 'cases/assigned_cases.dart';
import 'cases/case_history.dart';
import 'cases/new_case.dart';
import 'cases/unassigned_cases.dart';
import 'companies/companies.dart';
import 'interns/advocate_list.dart';
import 'interns/assigned_case_list.dart';
import 'interns/intern_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  ValueNotifier<int> assignedCasesCount = ValueNotifier<int>(-1);
  ValueNotifier<int> unassignedCasesCount = ValueNotifier<int>(-1);
  ValueNotifier<int> caseHistoryCount = ValueNotifier<int>(-1);
  ValueNotifier<int> internCount = ValueNotifier<int>(-1);
  ValueNotifier<int> advocateCount = ValueNotifier<int>(-1);
  ValueNotifier<int> companyCount = ValueNotifier<int>(-1);
  ValueNotifier<int> taskCount = ValueNotifier<int>(-1);
  String errorMessage = '';
  ValueNotifier<List<Case>> caseList = ValueNotifier<List<Case>>([]);
  int count = 0;
  bool isSupported = false;
  bool isNotificationAllowed = false;

  Future<void> fetchCaseCounter() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/get_case_counter'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          caseList.value = (responseData['data'] as List)
              .map((item) => Case.fromJson(item))
              .toList();
          unassignedCasesCount.value =
              int.parse(responseData['counters'][0]['unassigned_count']);
          assignedCasesCount.value =
              int.parse(responseData['counters'][1]['assigned_count']);
          caseHistoryCount.value =
              int.parse(responseData['counters'][2]['history_count']);
          advocateCount.value =
              int.parse(responseData['counters'][3]['advocate_count']);
          internCount.value =
              int.parse(responseData['counters'][4]['intern_count']);
          companyCount.value =
              int.parse(responseData['counters'][5]['company_count']);
          taskCount.value =
              int.parse(responseData['counters'][6]['task_count']);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to fetch data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchCaseCounter();
    allowNotification();
    AppBadgePlus.isSupported().then((value) {
      isSupported = value;
      setState(() {});
    });
    populateCaseData();
  }

  void allowNotification() async {
    if (await Permission.notification.isGranted) {
      isNotificationAllowed = true;
      setState(() {});
    } else {
      await Permission.notification.request().then((value) {
        if (value.isGranted) {
          isNotificationAllowed = true;
          setState(() {});
          print('Permission is granted');
        } else {
          print('Permission is not granted');
          isNotificationAllowed = false;
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    String getGreeting() {
      var hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Good Morning';
      } else if (hour < 17) {
        return 'Good Afternoon';
      } else {
        return 'Good Evening';
      }
    }

    double cardWidth = screenWidth * 0.40;
    double cardHeight = 72;
    double fullCardWidth = screenWidth * 0.93;
    double cardIconPositionX = cardWidth * 0.08;
    double cardIconPositionY = cardHeight * 0.21;
    double cardTextPositionY = cardHeight * 0.57;

    setBadgeNumber(int count) async {
      AppBadgePlus.updateBadge(4);
      print("${await AppBadgePlus.isSupported()}");
      print("Badge done");
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 56 + 30,
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Stack(
              children: [
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/notification.svg',
                    width: 35,
                    height: 35,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
                      builder: (context) => NotificationDrawer(
                        caseList: caseList.value,
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<List<Case>>(
                  valueListenable: caseList,
                  builder: (context, cases, child) {
                    setBadgeNumber(cases.length);
                    return cases.isNotEmpty
                        ? // Show badge only if there are notifications
                        Positioned(
                            right: 5,
                            top: -3,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFF292D32),
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                caseList.value.length.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 35,
                height: 35,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
                  builder: (context) => const SettingsDrawer(),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: SingleChildScrollView(
          child: RefreshIndicator(
            onRefresh: () async {
              fetchCaseCounter();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Advocate?>(
                  future: SharedPrefService.getUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: Colors.black,
                      );
                    } else if (snapshot.hasError) {
                      return const Text('Error loading user data');
                    } else if (snapshot.hasData && snapshot.data != null) {
                      Advocate user = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getGreeting(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              height: 0.95,
                            ),
                          ),
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: const Color.fromRGBO(37, 27, 70, 1.000),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Cases',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: cardWidth / cardHeight,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildCard(
                                title: 'Assigned Cases',
                                iconPath: 'assets/icons/assigned.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                iconPositionX: cardIconPositionX,
                                iconPositionY: cardIconPositionY,
                                textPositionY: cardTextPositionY,
                                destinationScreen: AssignedCases(),
                                shouldDisplayCounter: true,
                                counterNotifier: assignedCasesCount,
                              ),
                              _buildCard(
                                title: 'Unassigned Cases',
                                iconPath: 'assets/icons/unassigned.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                iconPositionX: cardIconPositionX,
                                iconPositionY: cardIconPositionY,
                                textPositionY: cardTextPositionY,
                                destinationScreen: UnassignedCases(),
                                shouldDisplayCounter: true,
                                counterNotifier: unassignedCasesCount,
                              ),
                              _buildCard(
                                title: 'Case History',
                                iconPath: 'assets/icons/case_history.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                iconPositionX: cardIconPositionX,
                                iconPositionY: cardIconPositionY,
                                textPositionY: cardTextPositionY,
                                destinationScreen: CaseHistoryScreen(),
                                shouldDisplayCounter: true,
                                counterNotifier: caseHistoryCount,
                              ),
                              _buildCard(
                                title: 'New Case',
                                iconPath: 'assets/icons/new_case.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                iconPositionX: cardIconPositionX,
                                iconPositionY: cardIconPositionY,
                                textPositionY: cardTextPositionY,
                                destinationScreen: NewCaseScreen(),
                                shouldDisplayCounter: false,
                                counterNotifier: ValueNotifier<int>(0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Interns',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: cardWidth / cardHeight,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildCard(
                                title: 'Intern List',
                                iconPath: 'assets/icons/intern_list.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                iconPositionX: cardIconPositionX,
                                iconPositionY: cardIconPositionY,
                                textPositionY: cardTextPositionY,
                                destinationScreen: InternListScreen(),
                                shouldDisplayCounter: true,
                                counterNotifier: internCount,
                              ),
                              _buildCard(
                                title: 'Advocate List',
                                iconPath: 'assets/icons/intern_list.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                iconPositionX: cardIconPositionX,
                                iconPositionY: cardIconPositionY,
                                textPositionY: cardTextPositionY,
                                destinationScreen: AdvocateListScreen(),
                                shouldDisplayCounter: true,
                                counterNotifier: advocateCount,
                              ),
                            ],
                          ),
                          _buildCard(
                            title: 'Tasks',
                            iconPath: 'assets/icons/tasks.svg',
                            cardWidth: fullCardWidth,
                            cardHeight: cardHeight,
                            iconPositionX: cardIconPositionX,
                            iconPositionY: cardIconPositionY,
                            textPositionY: cardTextPositionY,
                            destinationScreen: AssignedCaseList(),
                            shouldDisplayCounter: true,
                            counterNotifier: taskCount,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Companies',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildCard(
                            title: 'Companies',
                            iconPath: 'assets/icons/companies.svg',
                            cardWidth: fullCardWidth,
                            cardHeight: cardHeight,
                            iconPositionX: cardIconPositionX,
                            iconPositionY: cardIconPositionY,
                            textPositionY: cardTextPositionY,
                            destinationScreen: CompaniesScreen(),
                            shouldDisplayCounter: true,
                            counterNotifier: companyCount,
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    } else {
                      return const Text('User not found');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String iconPath,
    required double cardWidth,
    required double cardHeight,
    required double iconPositionX,
    required double iconPositionY,
    required double textPositionY,
    required Widget destinationScreen,
    bool shouldDisplayCounter = false,
    required ValueNotifier<int>
        counterNotifier, // <-- Use ValueNotifier for counter
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            var result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationScreen),
            );

            (result == true) ? null : result = false;

            if (result == false) {
              fetchCaseCounter(); // Refresh counters when returning
            }
          },
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              children: [
                Positioned(
                  left: iconPositionX,
                  top: iconPositionY,
                  child: SvgPicture.asset(iconPath, width: 24, height: 24),
                ),
                Positioned(
                  top: textPositionY,
                  left: iconPositionX,
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),

                      // Display Counter if applicable
                      if (shouldDisplayCounter) ...[
                        const SizedBox(
                            width: 6), // Spacer between text and counter
                        _CounterDisplay(
                            title: title, counterNotifier: counterNotifier)
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterDisplay extends StatelessWidget {
  final String title;
  final ValueNotifier<int> counterNotifier;

  const _CounterDisplay({required this.title, required this.counterNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: counterNotifier,
      builder: (context, value, child) {
        return value == -1 // Use -1 as a placeholder for loading state
            ? SizedBox(
                width: 20,
                height: 10,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
              )
            : Text(
                "($value)", // Show actual value, including 0
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black,
                ),
              );
      },
    );
  }
}
