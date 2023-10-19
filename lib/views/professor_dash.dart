import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:iiitr_connect/views/add_course_button.dart';
import 'package:iiitr_connect/views/course_view.dart';
import 'package:intl/intl.dart';

class ProfessorDashboard extends StatefulWidget {
  final String emailPrefix;
  final String name;

  const ProfessorDashboard({
    Key? key,
    required this.emailPrefix,
    required this.name,
  }) : super(key: key);

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  int currentPageIndex = 1;
  final controller = PageController(initialPage: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        onDestinationSelected: (int index) {
          controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 555),
            curve: Curves.easeInOutCubic,
          );
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: Theme.of(context).colorScheme.inversePrimary,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.school),
            icon: Icon(Icons.school_outlined),
            label: 'Courses',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.dashboard),
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.forum),
            icon: Icon(Icons.forum_outlined),
            label: 'Forum',
          ),
        ],
      ),
      body: SafeArea(
        child: PageView(
          onPageChanged: (value) {
            setState(() {
              currentPageIndex = value;
            });
          },
          controller: controller,
          children: <Widget>[
            Courses(dash: widget),
            Dashboard(widget: widget),
            Container(
              alignment: Alignment.center,
              child: const Text('Forum Page'),
            ),
          ],
        ),
      ),
    );
  }
}

class Courses extends StatefulWidget {
  const Courses({
    super.key,
    required this.dash,
  });

  final ProfessorDashboard dash;

  @override
  State<Courses> createState() => _CoursesState();
}

class _CoursesState extends State<Courses> {
  late Future<Map<String, dynamic>> coursesFuture;
  var loadCounter = 1;

  @override
  void initState() {
    coursesFuture =
        CourseApiController().getProfsCourses(widget.dash.emailPrefix);
    super.initState();
  }

  Future onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 50));
    coursesFuture =
        CourseApiController().getProfsCourses(widget.dash.emailPrefix);
    setState(() {
      loadCounter = loadCounter + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    return (loadCounter > 0)
        ? DefaultTabController(
            initialIndex: 0,
            length: 2,
            child: Scaffold(
              backgroundColor: const Color.fromARGB(0, 0, 0, 0),
              appBar: AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: 0,
                bottom: const TabBar(
                  tabs: <Widget>[
                    Tab(icon: Icon(Icons.calendar_today)),
                    Tab(icon: Icon(Icons.restore)),
                  ],
                ),
              ),
              floatingActionButton: AddCourseButton(
                profPrefix: widget.dash.emailPrefix,
                reloadCourses: () => onRefresh(),
              ),
              body: TabBarView(
                children: <Widget>[
                  RefreshIndicator(
                    onRefresh: onRefresh,
                    child: FutureBuilder(
                      // running courses builder
                      future: coursesFuture,
                      builder: (_, AsyncSnapshot snap) {
                        if (snap.connectionState == ConnectionState.done) {
                          if (snap.data != null) {
                            if (snap.data['status'] == 200) {
                              List<dynamic> courses =
                                  (snap.data['courses'] as List<dynamic>)
                                      .where((c) => c['is_running'])
                                      .toList(growable: false);
                              if (courses.isEmpty) {
                                return ListView(
                                  children: const [
                                    SizedBox(
                                      height: 100,
                                      child: Center(
                                          child: Text('No running courses')),
                                    )
                                  ],
                                );
                              }
                              return ListView.builder(
                                itemCount: courses.length,
                                itemBuilder: (_, index) {
                                  var startDate = DateFormat("yyyy-M-dd")
                                      .parse(courses[index]['begin_date']);
                                  return Card(
                                    clipBehavior: Clip.hardEdge,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return CourseView(
                                                courseId: courses[index]
                                                    ['course_id'],
                                                refreshCourses: onRefresh,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: ListTile(
                                        isThreeLine: true,
                                        titleAlignment:
                                            ListTileTitleAlignment.center,
                                        iconColor: (courses[index]
                                                ['accepting_reg'])
                                            ? Colors.green
                                            : Theme.of(context)
                                                .colorScheme
                                                .inversePrimary,
                                        leading: const Icon(Icons.book),
                                        title: Text(courses[index]['name']),
                                        subtitle: Text(
                                            '${courses[index]['course_code']} \n${DateFormat("MMMM").format(startDate)} ${startDate.year}'),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else if (snap.data['status'] == 404) {
                              return const Text('No courses');
                            } else {
                              SchedulerBinding.instance
                                  .addPostFrameCallback((_) {
                                scaffoldMessenger.hideCurrentSnackBar();
                                scaffoldMessenger.showSnackBar(SnackBar(
                                    content:
                                        Text(snap.data['message'] as String)));
                              });
                            }
                          } else {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              scaffoldMessenger.hideCurrentSnackBar();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please make sure you are connected to the internet'),
                                ),
                              );
                            });
                          }
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: onRefresh,
                    child: FutureBuilder(
                      // completed courses builder
                      future: coursesFuture,
                      builder: (_, AsyncSnapshot snap) {
                        if (snap.connectionState == ConnectionState.done) {
                          if (snap.data != null) {
                            if (snap.data['status'] == 200) {
                              List<dynamic> courses =
                                  (snap.data['courses'] as List<dynamic>)
                                      .where((c) => !c['is_running'])
                                      .toList(growable: false);
                              if (courses.isEmpty) {
                                return ListView(
                                  children: const [
                                    SizedBox(
                                      height: 100,
                                      child: Center(
                                          child: Text('No completed courses')),
                                    )
                                  ],
                                );
                              }
                              return ListView.builder(
                                itemCount: courses.length,
                                itemBuilder: (_, index) {
                                  var startDate = DateFormat("yyyy-M-dd")
                                      .parse(courses[index]['begin_date']);
                                  return Card(
                                    clipBehavior: Clip.hardEdge,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return CourseView(
                                                courseId: courses[index]
                                                    ['course_id'],
                                                refreshCourses: onRefresh,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: ListTile(
                                        isThreeLine: true,
                                        titleAlignment:
                                            ListTileTitleAlignment.center,
                                        iconColor: (courses[index]
                                                ['accepting_reg'])
                                            ? Colors.green
                                            : null,
                                        leading: const Icon(Icons.book),
                                        title: Text(courses[index]['name']),
                                        subtitle: Text(
                                            '${courses[index]['course_code']} \n${DateFormat("MMMM").format(startDate)} ${startDate.year}'),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else if (snap.data['status'] == 404) {
                              return const Text('No courses');
                            } else {
                              SchedulerBinding.instance
                                  .addPostFrameCallback((_) {
                                scaffoldMessenger.hideCurrentSnackBar();
                                scaffoldMessenger.showSnackBar(SnackBar(
                                    content:
                                        Text(snap.data['message'] as String)));
                              });
                            }
                          } else {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              scaffoldMessenger.hideCurrentSnackBar();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please make sure you are connected to the internet'),
                                ),
                              );
                            });
                          }
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        : const Placeholder();
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.widget,
  });

  final ProfessorDashboard widget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text(
            'Welcome, ${widget.name}!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
            ),
          ),
        ),
      ],
    );
  }
}
