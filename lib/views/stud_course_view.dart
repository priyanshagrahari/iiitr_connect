import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/attendance_api.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:iiitr_connect/api/lecture_api.dart';
import 'package:iiitr_connect/api/professor_api.dart';
import 'package:iiitr_connect/api/user_api.dart';
import 'package:iiitr_connect/views/course_students_view.dart';
import 'package:iiitr_connect/views/prof_course_view.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';

class StudCourseView extends StatefulWidget {
  const StudCourseView({
    super.key,
    required this.courseId,
    required this.studentRollNum,
    required this.refreshCourses,
  });

  final String courseId;
  final String studentRollNum;
  final Function refreshCourses;

  @override
  State<StudCourseView> createState() => _StudCourseViewState();
}

class _StudCourseViewState extends State<StudCourseView> {
  late Future courseFuture;
  CourseModel course = CourseModel.empty();

  late Future lecturesFuture;
  List<LectureModel> lectures = [];

  @override
  void initState() {
    super.initState();
    initFutures();
  }

  void initFutures() {
    courseFuture = CourseApiController().getCourse(courseId: widget.courseId);
    courseFuture.then((value) {
      if (!mounted) return;
      if (value['status'] == 200) {
        setState(() {
          course = CourseModel.fromMap(map: value['courses'][0]);
        });
      } else {
        setState(() {
          course = CourseModel.empty();
        });
      }
    });
    lecturesFuture = LectureApiController().getNLectures(widget.courseId, 0);
    lecturesFuture.then((value) {
      if (!mounted) return;
      if (value['status'] == 200) {
        var localLectures = List<LectureModel>.empty(growable: true);
        for (var lectureMap in value['lectures']) {
          localLectures.add(LectureModel.fromMap(map: lectureMap));
        }
        setState(() {
          lectures = localLectures;
        });
      } else if (mounted) {
        setState(() {
          lectures = [];
        });
      }
    });
  }

  @override
  void dispose() {
    courseFuture.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: FutureBuilder(
          future: courseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return SizedBox(
                height: Theme.of(context).buttonTheme.height - 15,
                width: Theme.of(context).buttonTheme.height - 15,
                child: LoadingIndicator(
                  indicatorType: Indicator.lineScale,
                  colors: [Theme.of(context).colorScheme.primary],
                  strokeWidth: 4.0,
                  pathBackgroundColor: Colors.black45,
                ),
              );
            } else {
              return Text(snapshot.data['courses'][0]['name']);
            }
          },
        ),
        centerTitle: true,
        actions: (UserType.userType == UserType.student)
            ? [
                IconButton(
                  // DROP COURSE
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: const Color.fromARGB(230, 0, 0, 0),
                      builder: (ctx) {
                        return CourseDropDialog(
                          courseId: widget.courseId,
                          studentRollNum: widget.studentRollNum,
                          onDrop: widget.refreshCourses,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.logout),
                ),
              ]
            : [],
      ),
      body: FutureBuilder(
        future: courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                initFutures();
              },
              child: ListView(
                children: [
                  ViewCourseCard(
                    course: course,
                    refreshCourses: widget.refreshCourses,
                  ),
                  Column(
                    children: [
                      SizedBox(
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ExpandedCardButton(
                              iconData: Icons.pie_chart,
                              labelString: "View Attendance",
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return StudentAttendancePieChartDialog(
                                      rollNum: widget.studentRollNum,
                                      courseId: widget.courseId,
                                      courseName: course.name,
                                    );
                                  },
                                );
                              },
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ExpandedCardButton(
                              iconData: Icons.people,
                              labelString: "Students",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return CourseStudentsView(
                                        courseId: widget.courseId,
                                        courseName: course.name,
                                      );
                                    },
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder(
                      future: lecturesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data['status'] == 200) {
                            var listTiles = lectures.map(
                              (e) {
                                return StudLectureCard(
                                  lecture: e,
                                  studentRoll: widget.studentRollNum,
                                );
                              },
                            ).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'All Lectures:',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                ...listTiles
                              ],
                            );
                          }
                          return const SizedBox();
                        }
                        return const SizedBox(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      })
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class StudentAttendancePieChartDialog extends StatefulWidget {
  const StudentAttendancePieChartDialog({
    super.key,
    required this.rollNum,
    required this.courseId,
    required this.courseName,
  });

  final String rollNum;
  final String courseId;
  final String courseName;

  @override
  State<StudentAttendancePieChartDialog> createState() =>
      _StudentAttendancePieChartDialogState();
}

class _StudentAttendancePieChartDialogState
    extends State<StudentAttendancePieChartDialog> with SingleTickerProviderStateMixin{
  late Future attendanceDataFuture;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  var sectionData = <PieChartSectionData>[];
  var radius = 150;
  var presentColor = Colors.green;
  var absentColor = Colors.red;
  var notMarkedColor = Colors.blueGrey;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    attendanceDataFuture = AttendanceApiController()
        .getStudentCourseAttendance(widget.courseId, widget.rollNum);
    attendanceDataFuture.then((value) {
      if (value['status'] == 200) {
        if (value['present'] > 0) {
          sectionData.add(PieChartSectionData(
              value: value['present'].toDouble(),
              color: presentColor,
              radius: 150,
              title:
                  "${(value['present'] / value['total'] * 100 as double).ceil()} %"));
        }
        if (value['absent'] > 0) {
          sectionData.add(PieChartSectionData(
              value: value['absent'].toDouble(),
              color: absentColor,
              radius: 150,
              title:
                  "${(value['absent'] / value['total'] * 100 as double).ceil()} %"));
        }
        if (value['not_marked'] > 0) {
          sectionData.add(PieChartSectionData(
              value: value['not_marked'].toDouble(),
              color: notMarkedColor,
              radius: 150,
              title:
                  "${(value['not_marked'] / value['total'] * 100 as double).ceil()} %"));
        }
        _controller.forward();
      } else if (value['status'] == 404) {
        sectionData.clear();
      } else {
        sectionData.clear();
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unknown error occured :(')));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Attendance Chart',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              title: const Text('Student Roll Number:'),
              titleTextStyle: Theme.of(context).textTheme.labelSmall,
              subtitle: Text(widget.rollNum),
              subtitleTextStyle: Theme.of(context).textTheme.titleMedium,
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              title: const Text('Course Name:'),
              titleTextStyle: Theme.of(context).textTheme.labelSmall,
              subtitle: Text(widget.courseName),
              subtitleTextStyle: Theme.of(context).textTheme.titleMedium,
            ),
            AspectRatio(
              aspectRatio: 1,
              child: FutureBuilder(
                  future: attendanceDataFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.done) {
                      if (sectionData.isNotEmpty) {
                        return PieChart(
                          PieChartData(
                            centerSpaceRadius: 0,
                            sections: sectionData,
                            startDegreeOffset: -90,
                          ),
                        );
                      } else {
                        return const Center(child: Text('Nothing to show'));
                      }
                    }
                    return const Center(child: CircularProgressIndicator());
                  }),
            ),
            SizeTransition(
              sizeFactor: _animation, 
              axis: Axis.vertical,
              axisAlignment: 1,
              child: FutureBuilder(
                future: attendanceDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Column(
                      children: sectionData.map((e) {
                        String title = "Present";
                        if (e.color == absentColor) {
                          title = "Absent";
                        } else if (e.color == notMarkedColor) {
                          title = "Not marked";
                        }
                        return ListTile(
                          visualDensity: const VisualDensity(vertical: VisualDensity.minimumDensity),
                          leading: Icon(
                            Icons.circle,
                            color: e.color,
                          ),
                          title: Text(title),
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class StudLectureCard extends StatefulWidget {
  const StudLectureCard({
    super.key,
    required this.lecture,
    required this.studentRoll,
  });

  final LectureModel lecture;
  final String studentRoll;

  @override
  State<StudLectureCard> createState() => _StudLectureCardState();
}

class _StudLectureCardState extends State<StudLectureCard>
    with SingleTickerProviderStateMixin {
  late Future studentPresentFuture;
  bool? present;

  bool collapsed = true;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    super.initState();
    studentPresentFuture = AttendanceApiController()
        .checkStudPresent(widget.lecture.lecture_id, widget.studentRoll);
    studentPresentFuture.then((value) {
      if (!mounted) return;
      if (value['status'] == 200 && value['present'] != null) {
        setState(() {
          present = value['present'];
        });
      } else {
        setState(() {
          present = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String formattedDateString(String date) {
    var dateObj = DateFormat('yyyy-MM-dd').parse(date);
    var format = DateFormat('EEEE, dd MMM yyyy');
    return format.format(dateObj);
  }

  void toggleCollapse() {
    if (collapsed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      collapsed = !collapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkResponse(
        splashColor: const Color.fromARGB(10, 255, 255, 255),
        onTap: toggleCollapse,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                // Lecture Date
                visualDensity:
                    const VisualDensity(vertical: VisualDensity.minimumDensity),
                leading: const Icon(Icons.calendar_today),
                titleTextStyle: Theme.of(context).textTheme.labelMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodyMedium,
                title: SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: -1,
                  child: const Text('Lecture Date'),
                ),
                subtitle: Text(
                    "Lecture on ${formattedDateString(widget.lecture.lecture_date)}"),
              ),
              ListTile(
                // Description
                visualDensity:
                    const VisualDensity(vertical: VisualDensity.minimumDensity),
                titleTextStyle: Theme.of(context).textTheme.labelMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                title: SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: -1,
                  child: const Text("Description"),
                ),
                subtitle: Text(widget.lecture.description),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FutureBuilder(
                    future: studentPresentFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                (present != null)
                                    ? (present!)
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.green,
                                          )
                                        : const Icon(
                                            Icons.person_off,
                                            color: Color.fromARGB(
                                                255, 226, 72, 69),
                                          )
                                    : const SizedBox(),
                                SizeTransition(
                                  sizeFactor: _animation,
                                  axis: Axis.horizontal,
                                  axisAlignment: -1,
                                  child: (present != null)
                                      ? (present!)
                                          ? const Row(
                                              children: [
                                                SizedBox(width: 10),
                                                Text(
                                                  "Present",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Row(
                                              children: [
                                                SizedBox(width: 10),
                                                Text(
                                                  "Absent",
                                                  style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 226, 72, 69),
                                                  ),
                                                ),
                                              ],
                                            )
                                      : const Text("Attendance not marked yet"),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircularProgressIndicator(),
                        ],
                      );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ViewCourseCard extends StatefulWidget {
  const ViewCourseCard({
    super.key,
    required this.course,
    required this.refreshCourses,
  });

  final CourseModel course;
  final Function refreshCourses;

  @override
  State<ViewCourseCard> createState() => _ViewCourseCardState();
}

class _ViewCourseCardState extends State<ViewCourseCard>
    with SingleTickerProviderStateMixin {
  late Future<List<String>> profNamesFuture;
  List<String> profNames = [];
  var collapsed = true;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    super.initState();
    profNamesFuture = getProfNames(widget.course.profs);
    profNamesFuture.then((value) {
      if (mounted) {
        setState(() {
          profNames = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<String>> getProfNames(List<String> prefixes) async {
    List<String> localNames = List.empty(growable: true);
    for (var prefix in prefixes) {
      var response = await ProfessorApiController().getData(prefix);
      if (mounted && response['status'] == 200) {
        localNames.add(response['professors'][0]['name']);
      }
    }
    return localNames;
  }

  void toggleCollapse() {
    if (collapsed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      collapsed = !collapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkResponse(
          splashColor: const Color.fromARGB(10, 255, 255, 255),
          onTap: toggleCollapse,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ListTile(
                visualDensity:
                    const VisualDensity(vertical: VisualDensity.minimumDensity),
                titleTextStyle: Theme.of(context).textTheme.labelMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                title: SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: 1,
                  child: const Text('Course Code:'),
                ),
                subtitle: Row(
                  children: [
                    SizeTransition(
                      sizeFactor: ReverseAnimation(_animation),
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: Text("Code: ${widget.course.course_code}"),
                    ),
                    SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.horizontal,
                      axisAlignment: 1,
                      child: Text(widget.course.course_code),
                    ),
                  ],
                ),
              ),
              SizeTransition(
                sizeFactor: _animation,
                axis: Axis.vertical,
                axisAlignment: 1,
                child: ListTile(
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
                  titleTextStyle: Theme.of(context).textTheme.labelMedium,
                  subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                  title: const Text('Course Name:'),
                  subtitle: Text(widget.course.name),
                ),
              ),
              ListTile(
                visualDensity:
                    const VisualDensity(vertical: VisualDensity.minimumDensity),
                titleTextStyle: Theme.of(context).textTheme.labelMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                title: SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: 1,
                  child: const Text('Begin Date:'),
                ),
                subtitle: Row(
                  children: [
                    SizeTransition(
                      sizeFactor: ReverseAnimation(_animation),
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: Text('Begin Date: ${widget.course.begin_date}'),
                    ),
                    SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.horizontal,
                      axisAlignment: 1,
                      child: Text(widget.course.begin_date),
                    ),
                  ],
                ),
              ),
              ListTile(
                visualDensity:
                    const VisualDensity(vertical: VisualDensity.minimumDensity),
                titleTextStyle: Theme.of(context).textTheme.labelMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                title: SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: 1,
                  child: const Text('End Date:'),
                ),
                subtitle: Row(
                  children: [
                    SizeTransition(
                      sizeFactor: ReverseAnimation(_animation),
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: Text('End Date: ${widget.course.end_date}'),
                    ),
                    SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.horizontal,
                      axisAlignment: 1,
                      child: Text(widget.course.end_date),
                    ),
                  ],
                ),
              ),
              SizeTransition(
                sizeFactor: _animation,
                axis: Axis.vertical,
                axisAlignment: 1,
                child: ListTile(
                    visualDensity: const VisualDensity(
                        vertical: VisualDensity.minimumDensity),
                    titleTextStyle: Theme.of(context).textTheme.labelMedium,
                    subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                    title: const Text('Professors:'),
                    subtitle: (profNames.isNotEmpty)
                        ? Text(profNames.join(', '))
                        : const Text('Loading...')),
              ),
              ListTile(
                visualDensity:
                    const VisualDensity(vertical: VisualDensity.minimumDensity),
                titleTextStyle: Theme.of(context).textTheme.labelMedium,
                subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                title: SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: 1,
                  child: const Text('Description:'),
                ),
                subtitle: Text(widget.course.description),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseDropDialog extends StatefulWidget {
  const CourseDropDialog({
    super.key,
    required this.courseId,
    required this.studentRollNum,
    required this.onDrop,
  });

  final String courseId;
  final String studentRollNum;
  final Function onDrop;

  @override
  State<CourseDropDialog> createState() => _CourseDropDialogState();
}

class _CourseDropDialogState extends State<CourseDropDialog> {
  late Future dropFuture;
  var dropping = false;

  @override
  void initState() {
    dropFuture = Future.delayed(const Duration(milliseconds: 1));
    super.initState();
  }

  @override
  void dispose() {
    dropFuture.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    return Dialog(
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to drop this course?',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
            ),
            Text(
              'All of your attendance data for this course will be lost forever.',
              style: TextStyle(
                  color: Colors.red[200],
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(
                      Colors.white,
                    ),
                    backgroundColor: MaterialStatePropertyAll(
                      Colors.red,
                    ),
                  ),
                  onPressed: (dropping)
                      ? null
                      : () {
                          setState(() {
                            dropping = true;
                            dropFuture = CourseApiController()
                                .toggleCourseRegistration(
                                    widget.courseId, widget.studentRollNum);
                            dropFuture.then((value) {
                              if (value != null) {
                                SchedulerBinding.instance
                                    .addPostFrameCallback((timeStamp) {
                                  scaffoldMessenger.hideCurrentSnackBar();
                                  scaffoldMessenger.showSnackBar(SnackBar(
                                      content:
                                          Text(value['message'] as String)));
                                  if (value['status'] == 200) {
                                    widget.onDrop();
                                    Navigator.of(context)
                                      ..pop()
                                      ..pop();
                                  }
                                });
                              }
                            });
                          });
                        },
                  child: (dropping)
                      ? SizedBox(
                          height: Theme.of(context).buttonTheme.height - 15,
                          width: Theme.of(context).buttonTheme.height - 15,
                          child: LoadingIndicator(
                            indicatorType: Indicator.lineScale,
                            colors: [Theme.of(context).colorScheme.primary],
                            strokeWidth: 4.0,
                            pathBackgroundColor: Colors.black45,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 10),
                            Text('Drop'),
                          ],
                        ),
                ),
                const SizedBox(width: 15),
                FilledButton(
                  onPressed: (dropping)
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
