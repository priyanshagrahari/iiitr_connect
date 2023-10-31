import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:iiitr_connect/views/courses_page.dart';
import 'package:loading_indicator/loading_indicator.dart';

class RegisterCourseButton extends StatelessWidget {
  const RegisterCourseButton({
    super.key,
    required this.studentRollNum,
    required this.reloadCourses,
  });

  final String studentRollNum;
  final Function reloadCourses;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      label: const Text('Register Course'),
      icon: const Icon(Icons.add),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return RegisterCoursePage(
                studentRollNum: studentRollNum,
                reloadCourses: reloadCourses,
              );
            },
          ),
        );
      },
    );
  }
}

class RegisterCoursePage extends StatefulWidget {
  const RegisterCoursePage({
    super.key,
    required this.studentRollNum,
    required this.reloadCourses,
  });

  final String studentRollNum;
  final Function reloadCourses;

  @override
  State<RegisterCoursePage> createState() => _RegisterCoursePageState();
}

class _RegisterCoursePageState extends State<RegisterCoursePage> {
  late Future regCoursesFuture;
  List<CourseModel> regCourses = [];

  var registering = false;

  @override
  void initState() {
    initFuture();
    super.initState();
  }

  void initFuture() {
    regCoursesFuture =
        CourseApiController().getRegCourses(widget.studentRollNum);
    regCoursesFuture.then((value) {
      if (mounted && value['status'] == 200) {
        print(value['courses']);
        setState(() {
          regCourses = (value['courses'] as List<dynamic>)
              .map((e) => CourseModel.fromMap(map: e))
              .toList();
        });
      } else {
        setState(() {
          regCourses = [];
        });
      }
    });
  }

  void onCourseTap(CourseModel e) async {
    await showDialog(
      context: context,
      builder: (context) {
        return RegConfirmDialog(
          course: e,
          reloadCourses: widget.reloadCourses,
          studentRollNum: widget.studentRollNum,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Course'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          initFuture();
        },
        child: FutureBuilder(
          future: regCoursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data['status'] == 200 && regCourses.isNotEmpty) {
                List<CourseListCard> cards = regCourses
                    .map((e) => CourseListCard(
                          course: e,
                          onRefresh: () {},
                          onTap: () => onCourseTap(e),
                        ))
                    .toList();
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Available courses:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ...cards
                  ],
                );
              } else {
                return ListView(
                  children: const [
                    SizedBox(
                      height: 100,
                      child: Center(
                          child: Text('No courses available for registration')),
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

class RegConfirmDialog extends StatefulWidget {
  const RegConfirmDialog({
    super.key,
    required this.course,
    required this.reloadCourses,
    required this.studentRollNum,
  });

  final CourseModel course;
  final Function reloadCourses;
  final String studentRollNum;

  @override
  State<RegConfirmDialog> createState() => _RegConfirmDialogState();
}

class _RegConfirmDialogState extends State<RegConfirmDialog> {
  bool registering = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !registering;
      },
      child: Dialog(
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ListTile(
                  visualDensity: const VisualDensity(
                    vertical: VisualDensity.maximumDensity,
                  ),
                  title: const Text("Confirm registration of course:"),
                  subtitleTextStyle: Theme.of(context).textTheme.titleLarge,
                  subtitle: Text(
                      '${widget.course.name} (${widget.course.course_code})'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    (registering)
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
                        : IconButton.filled(
                            onPressed: () async {
                              setState(() {
                                registering = true;
                              });
                              var response = await CourseApiController()
                                  .toggleCourseRegistration(
                                      widget.course.course_id,
                                      widget.studentRollNum);
                              if (response['message'] != null) {
                                SchedulerBinding.instance.addPostFrameCallback(
                                  (_) {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text(response['message'] as String),
                                      ),
                                    );
                                    if (response['status'] == 200) {
                                      widget.reloadCourses();
                                      Navigator.of(context)
                                        ..pop()
                                        ..pop();
                                    }
                                  },
                                );
                              }
                            },
                            icon: const Icon(Icons.check),
                          ),
                    IconButton(
                      onPressed: (registering)
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
