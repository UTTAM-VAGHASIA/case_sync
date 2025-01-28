import 'dart:convert';

import 'package:case_sync/models/advocate.dart';
import 'package:case_sync/services/case_services.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../models/case_list.dart';
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
  int assignedCasesCount = 0;
  int unassignedCasesCount = 0;
  int caseHistoryCount = 0;
  int internCount = 0;
  int advocateCount = 0;
  int companyCount = 0;
  int taskCount = 0;
  List<String> _assignedCaseIds = [];

  bool isLoaded = false;

  Future<int> fetchTaskCount() async {
    try {
      dynamic count = 0;
      final url = Uri.parse('$baseUrl/get_assigned_case_list');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _assignedCaseIds = (data['data'] as List)
              .map((item) => CaseListData.fromJson(item).id)
              .toList();
          print(_assignedCaseIds);

          for (final id in _assignedCaseIds) {
            final taskUrl = Uri.parse('$baseUrl/get_case_task');
            final request = http.MultipartRequest('POST', taskUrl);
            request.fields['case_no'] = id;
            final response = await request.send();

            if (response.statusCode == 200) {
              final responseBody = await response.stream.bytesToString();
              final data = jsonDecode(responseBody);

              if (data['success'] == true) {
                int temp = List<dynamic>.from(data['data']).length;
                print('$id: $temp');
                count += temp;
              } else {
                continue;
              }
            }
          }
          return count;
        } else {
          return 0;
        }
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }

    return 0;
  }

  @override
  void initState() {
    super.initState();
    initializeCounters();
  }

  void initializeCounters() async {
    assignedCasesCount = await AssignedCasesState().fetchCases(false);
    unassignedCasesCount = await UnassignedCasesState().fetchCases(false);
    caseHistoryCount = await populateCaseData();
    internCount = await InternListScreenState().fetchInterns(false);
    advocateCount = await AdvocateListScreenState().fetchAdvocates(false);
    companyCount = await CompaniesScreenState().fetchCompanies(false);
    taskCount = await fetchTaskCount();

    print('Assigned Cases Count: $assignedCasesCount');
    print('Unassigned Cases Count: $unassignedCasesCount');
    print('Case History Count: $caseHistoryCount');
    print('Interns Count: $internCount');
    print('Advocates Count: $advocateCount');
    print('Companies Count: $companyCount');
    print('Task Count: $taskCount');

    setState(() {
      isLoaded = true;
    });
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

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 56 + 30,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notification.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
              builder: (context) => const NotificationDrawer(),
            );
          },
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
                              isDataLoaded: isLoaded,
                              shouldDisplayCounter: true,
                              counter: assignedCasesCount,
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
                              isDataLoaded: isLoaded,
                              shouldDisplayCounter: true,
                              counter: unassignedCasesCount,
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
                                isDataLoaded: isLoaded,
                                shouldDisplayCounter: true,
                                counter: caseHistoryCount),
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
                              isDataLoaded: isLoaded,
                              shouldDisplayCounter: true,
                              counter: internCount,
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
                              isDataLoaded: isLoaded,
                              shouldDisplayCounter: true,
                              counter: advocateCount,
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
                          isDataLoaded: isLoaded,
                          shouldDisplayCounter: true,
                          counter: taskCount,
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
                          isDataLoaded: isLoaded,
                          shouldDisplayCounter: true,
                          counter: companyCount,
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
    bool isDataLoaded = true,
    int? counter,
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationScreen),
            );
          },
          splashColor: Colors.grey.withValues(alpha: 0.2),
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              children: [
                // Icon
                Positioned(
                  left: iconPositionX,
                  top: iconPositionY,
                  child: SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                  ),
                ),

                // Title and (optional) Counter
                Positioned(
                  top: textPositionY,
                  left: iconPositionX,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title always visible
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
                        isDataLoaded
                            ? Text(
                                "(${counter ?? 0})",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              )
                            : const SizedBox(
                                width: 20,
                                height: 12,
                                child: LinearProgressIndicator(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                              ),
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
