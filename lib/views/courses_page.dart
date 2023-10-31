import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:iiitr_connect/views/add_course_button.dart';
import 'package:iiitr_connect/views/prof_course_view.dart';
import 'package:iiitr_connect/views/stud_course_view.dart';
import 'package:intl/intl.dart';
import 'register_course_button.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({
    super.key,
    this.profPrefix,
    this.studRollNum,
  });

  final String? profPrefix;
  final String? studRollNum;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  late Future<Map<String, dynamic>> coursesFuture;
  List<CourseModel> allCourses = [];
  var loadCounter = 1;

  @override
  void initState() {
    initFuture();
    super.initState();
  }

  void initFuture() {
    if (widget.profPrefix != null) {
      coursesFuture = CourseApiController().getProfCourses(widget.profPrefix!);
    } else {
      coursesFuture = CourseApiController().getStudCourses(widget.studRollNum!);
    }
    coursesFuture.then((value) {
      if (mounted && value['status'] == 200) {
        setState(() {
          allCourses = (value['courses'] as List<dynamic>)
              .map((e) => CourseModel.fromMap(map: e))
              .toList();
        });
      } else {
        setState(() {
          allCourses = [];
        });
      }
    });
  }

  Future onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 50));
    initFuture();
    setState(() {
      loadCounter = loadCounter + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    final onCourseTap = (widget.profPrefix != null)
        ? (CourseModel course) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ProfCourseView(
                    courseId: course.course_id,
                    refreshCourses: onRefresh,
                  );
                },
              ),
            );
          }
        : (CourseModel course) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return StudCourseView(
                    courseId: course.course_id,
                    studentRollNum: widget.studRollNum!,
                    refreshCourses: onRefresh,
                  );
                },
              ),
            );
          };

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
              floatingActionButton: (widget.profPrefix != null)
                  ? AddCourseButton(
                      profPrefix: widget.profPrefix!,
                      reloadCourses: () => onRefresh(),
                    )
                  : RegisterCourseButton(
                      studentRollNum: widget.studRollNum!,
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
                              List<CourseModel> runningCourses = allCourses
                                  .where((element) => element.is_running)
                                  .toList();
                              if (runningCourses.isEmpty) {
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
                                itemCount: runningCourses.length,
                                itemBuilder: (_, index) {
                                  return CourseListCard(
                                    course: runningCourses[index],
                                    onRefresh: onRefresh,
                                    onTap: () => onCourseTap(runningCourses[index]),
                                  );
                                },
                              );
                            } else if (snap.data['status'] == 404) {
                              return ListView(
                                children: const [
                                  SizedBox(
                                    height: 100,
                                    child: Center(
                                        child: Text('No running courses')),
                                  )
                                ],
                              );
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
                              List<CourseModel> completedCourses = allCourses
                                  .where((element) => !element.is_running)
                                  .toList();
                              if (completedCourses.isEmpty) {
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
                                itemCount: completedCourses.length,
                                itemBuilder: (_, index) {
                                  return CourseListCard(
                                    course: completedCourses[index],
                                    onRefresh: onRefresh,
                                    onTap: () => onCourseTap(completedCourses[index]),
                                  );
                                },
                              );
                            } else if (snap.data['status'] == 404) {
                              return ListView(
                                children: const [
                                  SizedBox(
                                    height: 100,
                                    child: Center(
                                        child: Text('No completed courses')),
                                  )
                                ],
                              );
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

class CourseListCard extends StatefulWidget {
  const CourseListCard({
    super.key,
    required this.course,
    required this.onRefresh,
    required this.onTap,
  });

  final CourseModel course;
  final Function onRefresh;
  final Function onTap;

  @override
  State<CourseListCard> createState() => _CourseListCardState();
}

class _CourseListCardState extends State<CourseListCard> with AutomaticKeepAliveClientMixin {
  late Future numRegFuture;
  int numRegStudents = -1;

  @override
  void initState() {
    super.initState();
    numRegFuture = CourseApiController().getNumRegStudents(widget.course.course_id);
    numRegFuture.then((value) {
      if (mounted && value['status'] == 200) {
        setState(() {
          numRegStudents = value['count'];
        });
      }
      else {
        numRegStudents = -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var startDate = DateFormat("yyyy-M-dd").parse(widget.course.begin_date);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => widget.onTap(),
        child: Column(
          children: [
            ListTile(
              iconColor: (widget.course.accepting_reg)
                  ? Colors.green
                  : Theme.of(context).colorScheme.inversePrimary,
              leading: const Icon(Icons.book),
              titleTextStyle: Theme.of(context).textTheme.titleMedium,
              title: Text(widget.course.name),
            ),
            ListTile(
              visualDensity:
                  const VisualDensity(vertical: VisualDensity.minimumDensity),
              titleTextStyle: Theme.of(context).textTheme.labelSmall,
              subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
              title: const Text('Course Code'),
              subtitle: Text(widget.course.course_code),
              trailing: Column(
                children: [
                  const Icon(Icons.people),
                  FutureBuilder(future: numRegFuture, builder:(context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.data['status'] == 200 && numRegStudents != -1) {
                        return Text('$numRegStudents');
                      } else {
                        return const Text('0');
                      }
                    }
                    return const Text('-');
                  },),
                ],
              ),
            ),
            ListTile(
              visualDensity:
                  const VisualDensity(vertical: VisualDensity.minimumDensity),
              subtitle: Text(DateFormat("MMMM yyyy").format(startDate)),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}
