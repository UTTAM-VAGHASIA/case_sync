import 'dart:convert';

import 'package:case_sync/models/advocate.dart';
import 'package:case_sync/screens/cases/case_counter_list.dart';
import 'package:case_sync/services/case_services.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/notification.dart';
import 'appbar/notification_drawer.dart';
import 'appbar/settings_drawer.dart';
import 'cases/adding_forms/new_case.dart';
import 'cases/assigned_cases.dart';
import 'cases/case_history.dart';
import 'cases/todays_case_list.dart';
import 'cases/unassigned_cases.dart';
import 'companies/companies.dart';
import 'constants/constants.dart';
import 'interns/advocate_list.dart';
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
  ValueNotifier<int> newCaseCount = ValueNotifier<int>(-1);
  ValueNotifier<int> caseCounterCount = ValueNotifier<int>(-1);
  ValueNotifier<int> todaysCaseCount = ValueNotifier<int>(-1);
  String errorMessage = '';
  ValueNotifier<List<Notifications>> notificationList =
      ValueNotifier<List<Notifications>>([]);
  int count = 0;
  bool isSupported = false;
  bool isNotificationAllowed = false;

  Future<List<Notifications>> fetchCaseCounter() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/notifications'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          notificationList.value = (responseData['data'] as List)
              .map((item) => Notifications.fromJson(item))
              .toList();
          unassignedCasesCount.value =
              int.parse(responseData['counters'][0]['unassigned_count']);
          assignedCasesCount.value =
              int.parse(responseData['counters'][0]['assigned_count']);
          caseHistoryCount.value =
              int.parse(responseData['counters'][0]['history_count']);
          advocateCount.value =
              int.parse(responseData['counters'][0]['advocate_count']);
          internCount.value =
              int.parse(responseData['counters'][0]['intern_count']);
          companyCount.value =
              int.parse(responseData['counters'][0]['company_count']);
          taskCount.value =
              int.parse(responseData['counters'][0]['task_count']);
          newCaseCount.value = -2;
          caseCounterCount.value =
              int.parse(responseData['counters'][0]['counters_count']);
          todaysCaseCount.value =
              int.parse(responseData['counters'][0]['todays_case_count']);
          ;

          print("Notification List Added: ${notificationList.value}");

          await SharedPrefService.saveLastRefreshed(DateTime.now());
          return notificationList.value;
        }
      }
    } catch (e) {
      await SharedPrefService.saveLastRefreshed(DateTime.now());
      print(e);
      _showErrorSnackBar('Failed to fetch data: $e');
    }

    if (assignedCasesCount.value == -1) {
      assignedCasesCount.value = 0;
      unassignedCasesCount.value = 0;
      caseHistoryCount.value = 0;
      advocateCount.value = 0;
      internCount.value = 0;
      companyCount.value = 0;
      taskCount.value = 0;
      todaysCaseCount.value = 0;
      caseCounterCount.value = 0;
      newCaseCount.value = -2;
      print("Entered If");
    }
    print("Hellooooo");

    await SharedPrefService.saveLastRefreshed(DateTime.now());
    return [];
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showErrorSnackBar(context, message);
  }

  @override
  void initState() {
    super.initState();
    allowNotification();
    fetchCaseCounter();
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

    // setBadgeNumber(int count) async {
    //   await FlutterNewBadger.setBadge(count);
    //   print("Badge done: ${await FlutterNewBadger.getBadge()}");
    // }

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
                    HapticFeedback.mediumImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
                      builder: (context) => NotificationDrawer(
                        caseList: notificationList.value,
                        onRefresh: fetchCaseCounter,
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<List<Notifications>>(
                  valueListenable: notificationList,
                  builder: (context, cases, child) {
                    return Positioned(
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
                          notificationList.value.length.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
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
                HapticFeedback.mediumImpact();
                showModalBottomSheet(
                  isScrollControlled: false,
                  context: context,
                  backgroundColor: Color(0xFFF3F3F3),
                  builder: (context) => const SettingsDrawer(),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: LiquidPullToRefresh(
          backgroundColor: Colors.black,
          color: Colors.transparent,
          showChildOpacityTransition: false,
          onRefresh: () async {
            fetchCaseCounter();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
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
                            'Notice',
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
                                title: 'Case Counter',
                                iconPath: 'assets/icons/case_counter.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                destinationScreen: CounterCases(),
                                counterNotifier: caseCounterCount,
                                shouldDisplayCounter: true,
                              ),
                              _buildCard(
                                title: 'Upcoming Cases',
                                iconPath: 'assets/icons/cases_today.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                destinationScreen: UpcomingCases(),
                                counterNotifier: todaysCaseCount,
                                shouldDisplayCounter: true,
                              ),
                            ],
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
                                destinationScreen: AssignedCases(),
                                counterNotifier: assignedCasesCount,
                                shouldDisplayCounter: true,
                              ),
                              _buildCard(
                                title: 'Unassigned Cases',
                                iconPath: 'assets/icons/unassigned.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                destinationScreen: UnassignedCases(),
                                counterNotifier: unassignedCasesCount,
                                shouldDisplayCounter: true,
                              ),
                              _buildCard(
                                title: 'Case History',
                                iconPath: 'assets/icons/case_history.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                destinationScreen: CaseHistoryScreen(),
                                counterNotifier: caseHistoryCount,
                                shouldDisplayCounter: true,
                              ),
                              _buildCard(
                                title: 'New Case',
                                iconPath: 'assets/icons/new_case.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                destinationScreen: NewCaseScreen(),
                                counterNotifier: newCaseCount,
                                shouldDisplayCounter: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Officials',
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
                                destinationScreen: InternListScreen(),
                                counterNotifier: internCount,
                                shouldDisplayCounter: true,
                              ),
                              _buildCard(
                                title: 'Advocate List',
                                iconPath: 'assets/icons/intern_list.svg',
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                destinationScreen: AdvocateListScreen(),
                                counterNotifier: advocateCount,
                                shouldDisplayCounter: true,
                              ),
                            ],
                          ),
                          // _buildCard(
                          //   title: 'Tasks',
                          //   iconPath: 'assets/icons/tasks.svg',
                          //   cardWidth: fullCardWidth,
                          //   cardHeight: cardHeight,
                          //   destinationScreen: AssignedCaseList(),
                          //   counterNotifier: taskCount,
                          //   shouldDisplayCounter: true,
                          // ),
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
                            destinationScreen: CompaniesScreen(),
                            counterNotifier: companyCount,
                            shouldDisplayCounter: true,
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
    required Widget destinationScreen,
    bool shouldDisplayCounter = false,
    required ValueNotifier<int> counterNotifier,
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
            HapticFeedback.mediumImpact();
            var result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationScreen),
            );

            fetchCaseCounter();
          },
          child: Stack(
            children: [
              // Card Content (Icon + Title)
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),
                          SvgPicture.asset(iconPath, width: 30, height: 30),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Badge positioned at the top-right corner
              if (shouldDisplayCounter)
                Positioned(
                  top: ((cardHeight / 2) - 19),
                  right: 8,
                  child: _BadgeCounter(counterNotifier: counterNotifier),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCounter extends StatelessWidget {
  final ValueNotifier<int> counterNotifier;

  const _BadgeCounter({required this.counterNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: counterNotifier,
      builder: (context, value, child) {
        return Container(
          width: 40,
          // Fixed size for uniformity
          height: 40,
          decoration: BoxDecoration(
            color: value == -1 ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(30), // Circular shape
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: value == -1
              ? SizedBox(
                  width: 18,
                  height: 6,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white,
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : Text(
                  "${value == -2 ? "</>" : value}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
        );
      },
    );
  }
}
