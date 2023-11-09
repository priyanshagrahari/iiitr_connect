import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:iiitr_connect/api/student_api.dart';
import 'package:iiitr_connect/api/user_api.dart';
import 'package:iiitr_connect/views/stud_course_view.dart';
import 'package:loading_indicator/loading_indicator.dart';

class CourseStudentsView extends StatefulWidget {
  const CourseStudentsView({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  final String courseId;
  final String courseName;

  @override
  State<CourseStudentsView> createState() => _CourseStudentsViewState();
}

class _CourseStudentsViewState extends State<CourseStudentsView> {
  late Future studentsFuture;
  List<StudentModel> courseStudents = [];

  String searchQuery = "";
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    initFuture();
  }

  void initFuture() {
    studentsFuture = StudentApiController().getByCourse(widget.courseId);
    studentsFuture.then((value) {
      if (!mounted) return;
      if (value['status'] == 200) {
        var localList = List<StudentModel>.empty(growable: true);
        for (var registration in value['registrations']) {
          localList.add(StudentModel.fromMap(map: registration['student']));
        }
        setState(() {
          courseStudents = localList;
        });
      } else {
        setState(() {
          courseStudents = [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (isSearching)
            ? TextField(
                autofocus: true,
                onChanged: (value) => setState(() {
                  searchQuery = value;
                }),
              )
            : const Text('Registered Students'),
        centerTitle: true,
        leading: (isSearching)
            ? IconButton(
                onPressed: () {
                  setState(() {
                    searchQuery = "";
                    isSearching = false;
                  });
                },
                icon: const Icon(Icons.close),
              )
            : null,
        actions: (isSearching)
            ? null
            : [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isSearching = true;
                    });
                  },
                  icon: const Icon(Icons.search),
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          initFuture();
        },
        child: FutureBuilder(
          future: studentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List<StudentModel> queryStudents = courseStudents
                  .where((e) =>
                      e.name.toLowerCase().contains(searchQuery) ||
                      e.roll_num.contains(searchQuery))
                  .toList();
              if (snapshot.data['status'] == 200 && queryStudents.isNotEmpty) {
                return ListView.builder(
                  itemCount: queryStudents.length,
                  itemBuilder: (context, index) => StudentCard(
                    student: queryStudents[index],
                    onDrop: () => initFuture(),
                    courseId: (UserType.userType >= UserType.separator)
                        ? widget.courseId
                        : null,
                    courseName: (UserType.userType >= UserType.separator)
                        ? widget.courseName
                        : null,
                  ),
                );
              } else {
                return ListView(
                  children: const [
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('No registered students'),
                      ),
                    ),
                  ],
                );
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class StudentCard extends StatefulWidget {
  const StudentCard({
    super.key,
    required this.student,
    this.courseId,
    this.courseName,
    required this.onDrop,
  });

  final StudentModel student;
  final String? courseId;
  final String? courseName;
  final Function onDrop;

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard>
    with TickerProviderStateMixin {
  var collapsed = true;
  var dropping = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  late final AnimationController _dropController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _dropAnimation = CurvedAnimation(
    parent: _dropController,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dropController.dispose();
    super.dispose();
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
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkResponse(
          splashColor: const Color.fromARGB(10, 255, 255, 255),
          onTap: toggleCollapse,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  // ROLL NUMBER
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
                  leading: const Icon(Icons.assignment_ind),
                  titleTextStyle: Theme.of(context).textTheme.labelMedium,
                  subtitleTextStyle: Theme.of(context).textTheme.bodyMedium,
                  title: SizeTransition(
                    sizeFactor: _animation,
                    axis: Axis.vertical,
                    axisAlignment: -1,
                    child: const Text('Roll Number'),
                  ),
                  subtitle: Text(widget.student.roll_num),
                ),
                ListTile(
                  // STUDENT NAME
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
                  titleTextStyle: Theme.of(context).textTheme.labelMedium,
                  subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                  title: SizeTransition(
                    sizeFactor: _animation,
                    axis: Axis.vertical,
                    axisAlignment: -1,
                    child: const Text("Name"),
                  ),
                  subtitle: Text(widget.student.name),
                ),
                (widget.courseId != null)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizeTransition(
                            sizeFactor: ReverseAnimation(_dropAnimation),
                            axis: Axis.horizontal,
                            axisAlignment: -1,
                            child: TextButton(
                              // ATTENDANCE BUTTON
                              child: Row(
                                children: [
                                  const Icon(Icons.pie_chart),
                                  SizeTransition(
                                    sizeFactor: _animation,
                                    axis: Axis.horizontal,
                                    axisAlignment: -1,
                                    child: const Row(
                                      children: [
                                        SizedBox(width: 10),
                                        Text("Attendance"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return StudentAttendancePieChartDialog(
                                      rollNum: widget.student.roll_num,
                                      courseId: widget.courseId!,
                                      courseName: widget.courseName!,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          SizeTransition(
                            sizeFactor: ReverseAnimation(_dropAnimation),
                            axis: Axis.horizontal,
                            axisAlignment: -1,
                            child: TextButton(
                              // DROP BUTTON
                              child: (dropping)
                                  ? SizedBox(
                                      height:
                                          Theme.of(context).buttonTheme.height -
                                              15,
                                      width:
                                          Theme.of(context).buttonTheme.height -
                                              15,
                                      child: LoadingIndicator(
                                        indicatorType: Indicator.lineScale,
                                        colors: [
                                          Theme.of(context).colorScheme.primary
                                        ],
                                        strokeWidth: 4.0,
                                        pathBackgroundColor: Colors.black45,
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        const Icon(Icons.logout),
                                        SizeTransition(
                                          sizeFactor: _animation,
                                          axis: Axis.horizontal,
                                          axisAlignment: -1,
                                          child: const Row(
                                            children: [
                                              SizedBox(width: 10),
                                              Text("Drop"),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                              onPressed: () {
                                _dropController.forward();
                              },
                            ),
                          ),
                          SizeTransition(
                            sizeFactor: _dropAnimation,
                            axis: Axis.horizontal,
                            axisAlignment: 1,
                            child: Row(
                              children: [
                                const Text('Are you sure? '),
                                IconButton(
                                  // CONFIRM DELETE
                                  onPressed: () async {
                                    _dropController.reverse();
                                    setState(() {
                                      dropping = true;
                                    });
                                    var response = await CourseApiController()
                                        .toggleCourseRegistration(
                                      widget.courseId!,
                                      widget.student.roll_num,
                                    );
                                    if (response['message'] != null) {
                                      SchedulerBinding.instance
                                          .addPostFrameCallback(
                                        (_) {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text((response[
                                                          'status'] ==
                                                      200)
                                                  ? "Student removed from course"
                                                  : (response['message']
                                                      as String)),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                    if (mounted && response['status'] == 200) {
                                      widget.onDrop();
                                    } else {
                                      setState(() {
                                        dropping = false;
                                      });
                                    }
                                  },
                                  color: Colors.red,
                                  icon: const Icon(Icons.check),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _dropController.reverse();
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
