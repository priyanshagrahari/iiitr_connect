import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:collection/collection.dart';
import 'package:iiitr_connect/api/lecture_api.dart';
import 'package:iiitr_connect/views/add_course_button.dart';
import 'package:iiitr_connect/views/add_lecture_form.dart';
import 'package:iiitr_connect/views/all_lectures.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';

class CourseView extends StatefulWidget {
  const CourseView({
    super.key,
    required this.courseId,
    required this.refreshCourses,
  });

  final String courseId;
  final Function refreshCourses;

  @override
  State<CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  late Future courseFuture;
  late Future last5LecturesFuture;
  CourseModel course = CourseModel.empty();
  List<LectureModel> last5Lectures = [];

  @override
  void initState() {
    initFutures();
    super.initState();
  }

  /// what = 0: get all, 1: only courses, 2: only lectures
  void initFutures({int what = 0}) {
    if (what == 0 || what == 1) {
      courseFuture = CourseApiController().getCourse(courseId: widget.courseId);
      courseFuture.then((value) {
        if (mounted) {
          setState(() {
            course = CourseModel.fromMap(map: value['courses'][0]);
          });
        }
      });
    }
    if (what == 0 || what == 2) {
      last5LecturesFuture =
          LectureApiController().getNLectures(widget.courseId, 5);
      last5LecturesFuture.then((value) {
        if (mounted && value['lectures'] != null) {
          setState(() {
            last5Lectures = (value['lectures'] as List<dynamic>)
                .map((e) => LectureModel.fromMap(map: e))
                .toList();
          });
        } else {
          setState(() {
            last5Lectures = [];
          });
        }
      });
    }
  }

  @override
  void dispose() {
    courseFuture.ignore();
    last5LecturesFuture.ignore();
    super.dispose();
  }

  Future onRefresh() async {
    initFutures(what: 1);
    widget.refreshCourses();
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
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    return CourseDeleteDialog(
                      courseId: widget.courseId,
                      popUntil: "/profDash",
                      onDelete: widget.refreshCourses,
                    );
                  },
                );
              },
              icon: const Icon(Icons.delete_forever),
            ),
          ],
        ),
        body: FutureBuilder(
          future: courseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  children: [
                    EditCourseCard(
                      course: course,
                      onRefresh: () => initFutures(what: 1),
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
                                iconData: Icons.post_add_outlined,
                                label: "Add Lecture",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return AddLectureForm(
                                          courseId: widget.courseId,
                                          reloadLectures: () =>
                                              initFutures(what: 2),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              ExpandedCardButton(
                                iconData: Icons.insert_chart_outlined_outlined,
                                label: "All Lectures",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return AllLectures(
                                          courseId: widget.courseId,
                                          onDeleteOrUpdate: () =>
                                              initFutures(what: 2),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
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
                                label: "Students",
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder(
                      future: last5LecturesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data['status'] == 200) {
                            var listTiles = last5Lectures.map(
                              (e) {
                                return LectureCard(
                                  lectureId: e.lecture_id,
                                  onUpdate: () {},
                                  onDelete: () => initFutures(what: 2),
                                );
                              },
                            ).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Recent Lectures:',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                ...listTiles
                              ],
                            );
                          }
                          return const SizedBox(
                            // height: 100,
                            // child: Center(
                            //   child: Text("No lectures found"),
                            // ),
                          );
                        }
                        return const SizedBox(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    )
                  ],
                ),
              );
            }
          },
        ));
  }
}

class LectureCard extends StatefulWidget {
  const LectureCard({
    super.key,
    required this.lectureId,
    required this.onUpdate,
    required this.onDelete,
  });

  final String lectureId;
  final Function onUpdate;
  final Function onDelete;

  @override
  State<LectureCard> createState() => _LectureCardState();
}

class _LectureCardState extends State<LectureCard>
    with TickerProviderStateMixin {
  late Future lectureFuture;
  LectureModel lecture = LectureModel.empty();

  var collapsed = true;
  var deleting = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  late final AnimationController _deleteController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _deleteAnimation = CurvedAnimation(
    parent: _deleteController,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    setFuture();
    super.initState();
  }

  void setFuture() {
    lectureFuture = LectureApiController().getLecture(widget.lectureId);
    lectureFuture.then((value) {
      if (mounted && value['status'] == 200) {
        setState(() {
          lecture = LectureModel.fromMap(map: value['lectures'][0]);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _deleteController.dispose();
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
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

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
            child: FutureBuilder(
                future: lectureFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      lecture.lecture_id.isNotEmpty) {
                    if (snapshot.data['status'] == 200) {
                      return Column(
                        children: [
                          ListTile(
                            // Lecture Date
                            visualDensity: const VisualDensity(
                                vertical: VisualDensity.minimumDensity),
                            leading: const Icon(Icons.calendar_today),
                            titleTextStyle:
                                Theme.of(context).textTheme.labelMedium,
                            subtitleTextStyle:
                                Theme.of(context).textTheme.bodyMedium,
                            title: SizeTransition(
                              sizeFactor: _animation,
                              axis: Axis.vertical,
                              axisAlignment: -1,
                              child: const Text('Lecture Date'),
                            ),
                            subtitle: Text(
                                "Lecture on ${formattedDateString(lecture.lecture_date)}"),
                          ),
                          ListTile(
                            // Description
                            visualDensity: const VisualDensity(
                                vertical: VisualDensity.minimumDensity),
                            titleTextStyle:
                                Theme.of(context).textTheme.labelMedium,
                            subtitleTextStyle:
                                Theme.of(context).textTheme.bodyLarge,
                            title: SizeTransition(
                              sizeFactor: _animation,
                              axis: Axis.vertical,
                              axisAlignment: -1,
                              child: const Text("Description"),
                            ),
                            subtitle: Text(lecture.description),
                            trailing: SizedBox(
                              width: 50,
                              child: SizeTransition(
                                sizeFactor: _animation,
                                axis: Axis.vertical,
                                axisAlignment: 1,
                                child: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      EditCourseCard.showTextEditor(
                                    context: context,
                                    fieldName: "Description",
                                    fieldInitValue: lecture.description,
                                    onSubmit: (value) {
                                      // SAVE
                                      lecture.description = value;
                                      lectureFuture = LectureApiController()
                                          .updateLecture(
                                              lecture.lecture_id, lecture);
                                      lectureFuture.then((value) {
                                        if (mounted && value['status'] == 200) {
                                          setState(() {
                                            lecture = LectureModel(
                                              lecture_id: lecture.lecture_id,
                                              course_id: value['course_id'],
                                              lecture_date:
                                                  value['lecture_date'],
                                              description: value['description'],
                                            );
                                          });
                                          widget.onUpdate();
                                          SchedulerBinding.instance
                                              .addPostFrameCallback(
                                                  (timeStamp) {
                                            scaffoldMessenger
                                                .hideCurrentSnackBar();
                                            scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        value['message']
                                                            as String)));
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                // ATTENDANCE BUTTON
                                child: Row(
                                  children: [
                                    const Icon(Icons.add_chart),
                                    SizeTransition(
                                      sizeFactor: _animation,
                                      axis: Axis.horizontal,
                                      axisAlignment: -1,
                                      child: const Row(
                                        children: [
                                          SizedBox(width: 10),
                                          Text("Mark Attendance"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onPressed: () {},
                              ),
                              SizeTransition(
                                sizeFactor: ReverseAnimation(_deleteAnimation),
                                axis: Axis.horizontal,
                                axisAlignment: -1,
                                child: TextButton(
                                  // DELETE BUTTON
                                  child: (deleting)
                                      ? SizedBox(
                                          height: Theme.of(context)
                                                  .buttonTheme
                                                  .height -
                                              15,
                                          width: Theme.of(context)
                                                  .buttonTheme
                                                  .height -
                                              15,
                                          child: LoadingIndicator(
                                            indicatorType: Indicator.lineScale,
                                            colors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                            ],
                                            strokeWidth: 4.0,
                                            pathBackgroundColor: Colors.black45,
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            const Icon(Icons.delete_forever),
                                            SizeTransition(
                                              sizeFactor: _animation,
                                              axis: Axis.horizontal,
                                              axisAlignment: -1,
                                              child: const Row(
                                                children: [
                                                  SizedBox(width: 10),
                                                  Text("Delete"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                  onPressed: () {
                                    _deleteController.forward();
                                  },
                                ),
                              ),
                              SizeTransition(
                                sizeFactor: _deleteAnimation,
                                axis: Axis.horizontal,
                                axisAlignment: 1,
                                child: Row(
                                  children: [
                                    const Text('Are you sure? '),
                                    IconButton(
                                      onPressed: () async {
                                        _deleteController.reverse();
                                        setState(() {
                                          deleting = true;
                                        });
                                        var response =
                                            await LectureApiController()
                                                .deleteLecture(
                                                    lecture.lecture_id);
                                        if (response['status'] == 200) {
                                          widget.onDelete();
                                        }
                                      },
                                      color: Colors.red,
                                      icon: const Icon(Icons.check),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _deleteController.reverse();
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      );
                    } else {
                      return const SizedBox(
                        height: 50,
                        child: Center(
                          child: Text(
                              'Not found :( Please contact an administrator about this issue'),
                        ),
                      );
                    }
                  }
                  return const SizedBox(
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class ExpandedCardButton extends StatelessWidget {
  const ExpandedCardButton({
    super.key,
    required this.iconData,
    required this.label,
    required this.onTap,
  });

  final IconData iconData;
  final String label;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 5.0,
        margin: const EdgeInsets.all(5),
        color: Theme.of(context).colorScheme.inversePrimary,
        child: InkResponse(
          containedInkWell: true,
          splashColor: Theme.of(context).colorScheme.onInverseSurface,
          onTap: () => onTap(),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
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

class EditCourseCard extends StatefulWidget {
  const EditCourseCard({
    super.key,
    required this.course,
    required this.onRefresh,
    required this.refreshCourses,
  });

  final CourseModel course;
  final Function onRefresh;
  final Function refreshCourses;

  @override
  State<EditCourseCard> createState() => _EditCourseCardState();

  static void showTextEditor({
    required final BuildContext context,
    required final String fieldName,
    required final String fieldInitValue,
    required void Function(String value) onSubmit,
    var fieldMaxLines = 1,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        var fieldKey = GlobalKey<FormFieldState>();
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Edit $fieldName:'),
                TextFormField(
                  key: fieldKey,
                  minLines: 1,
                  maxLines: fieldMaxLines,
                  initialValue: fieldInitValue,
                  autofocus: true,
                  onEditingComplete: () {
                    if (fieldKey.currentState!.validate()) {
                      onSubmit(fieldKey.currentState!.value.toString().trim());
                      Navigator.pop(context);
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return null;
                    } else {
                      return "Please enter a ${fieldName.toLowerCase()}";
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showCalendar({
    required final BuildContext context,
    required String calendarInitValue,
    required void Function(String value) onSubmit,
    var firstDateString,
    var lastDateString,
  }) async {
    var initDate = (calendarInitValue.isNotEmpty)
        ? DateFormat("yyyy-MM-dd").parse(calendarInitValue)
        : DateTime.now();
    var firstDate =
        (firstDateString != null && (firstDateString as String).isNotEmpty)
            ? DateFormat("yyyy-MM-dd").parse(firstDateString)
            : DateTime.now().subtract(const Duration(days: 365));
    var lastDate =
        (lastDateString != null && (lastDateString as String).isNotEmpty)
            ? DateFormat("yyyy-MM-dd").parse(lastDateString)
            : DateTime.now().add(const Duration(days: 365));
    if (initDate.isBefore(firstDate)) {
      initDate = firstDate;
    }
    if (initDate.isAfter(lastDate)) {
      initDate = lastDate;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      var dateString = picked.toString().split(' ')[0];
      onSubmit(dateString);
    }
  }
}

class _EditCourseCardState extends State<EditCourseCard>
    with SingleTickerProviderStateMixin {
  late CourseModel localCourse;
  List<String> initProfNames = [];
  List<String> profNames = [];
  var modified = false;
  var collapsed = true;
  var saving = false;

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
    localCourse = CourseModel.empty();
    reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void reset() {
    setState(() {
      setState(() {
        localCourse.accepting_reg = widget.course.accepting_reg;
        localCourse.course_code = widget.course.course_code;
        localCourse.name = widget.course.name;
        localCourse.begin_date = widget.course.begin_date;
        localCourse.end_date = widget.course.end_date;
        localCourse.description = widget.course.description;
        localCourse.profs.clear();
        localCourse.profs.addAll(widget.course.profs);
        profNames.clear();
        profNames.addAll(initProfNames);
        modified = false;
      });
    });
  }

  void checkModified() {
    setState(() {
      modified = (localCourse.accepting_reg != widget.course.accepting_reg) ||
          (localCourse.course_code != widget.course.course_code) ||
          (localCourse.name != widget.course.name) ||
          (localCourse.begin_date != widget.course.begin_date) ||
          (localCourse.end_date != widget.course.end_date) ||
          (localCourse.description != widget.course.description) ||
          !((const ListEquality())
              .equals(localCourse.profs, widget.course.profs));
    });
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
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 10),
                ListTile(
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
                  titleTextStyle: Theme.of(context).textTheme.bodyLarge,
                  title: Row(
                    children: [
                      const Text("Registrations "),
                      SizeTransition(
                        sizeFactor: ReverseAnimation(_animation),
                        axis: Axis.horizontal,
                        axisAlignment: 1,
                        child: Text(
                            widget.course.accepting_reg ? "Open" : "Closed"),
                      ),
                      SizeTransition(
                        sizeFactor: _animation,
                        axis: Axis.horizontal,
                        axisAlignment: -1,
                        child:
                            Text(localCourse.accepting_reg ? "Open" : "Closed"),
                      ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 70,
                    child: SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.vertical,
                      axisAlignment: 1,
                      child: Switch(
                        value: localCourse.accepting_reg,
                        onChanged: (value) {
                          setState(() {
                            localCourse.accepting_reg = value;
                          });
                          checkModified();
                        },
                      ),
                    ),
                  ),
                ),
                ListTile(
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
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
                        child:
                            Text("Course Code: ${widget.course.course_code}"),
                      ),
                      SizeTransition(
                        sizeFactor: _animation,
                        axis: Axis.horizontal,
                        axisAlignment: 1,
                        child: Text(localCourse.course_code),
                      ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 50,
                    child: SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.vertical,
                      axisAlignment: 1,
                      child: IconButton(
                        onPressed: () => EditCourseCard.showTextEditor(
                          context: context,
                          fieldName: 'Course Code',
                          fieldInitValue: localCourse.course_code,
                          onSubmit: (value) {
                            setState(() {
                              localCourse.course_code = value;
                            });
                            checkModified();
                          },
                        ),
                        icon: const Icon(Icons.edit),
                      ),
                    ),
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
                    subtitle: Text(localCourse.name),
                    trailing: IconButton(
                      onPressed: () => EditCourseCard.showTextEditor(
                        context: context,
                        fieldName: 'Course Name',
                        fieldInitValue: localCourse.name,
                        onSubmit: (value) {
                          setState(() {
                            localCourse.name = value;
                          });
                          checkModified();
                        },
                      ),
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                ),
                ListTile(
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
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
                        child: Text(localCourse.begin_date),
                      ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 50,
                    child: SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.vertical,
                      axisAlignment: 1,
                      child: IconButton(
                        onPressed: () => EditCourseCard.showCalendar(
                          context: context,
                          calendarInitValue: localCourse.begin_date,
                          lastDateString: localCourse.end_date,
                          onSubmit: (value) {
                            setState(() {
                              localCourse.begin_date = value;
                            });
                            checkModified();
                          },
                        ),
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
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
                        child: Text(localCourse.end_date),
                      ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 50,
                    child: SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.vertical,
                      axisAlignment: 1,
                      child: IconButton(
                        onPressed: () => EditCourseCard.showCalendar(
                          context: context,
                          calendarInitValue: localCourse.end_date,
                          firstDateString: localCourse.begin_date,
                          onSubmit: (value) {
                            setState(() {
                              localCourse.end_date = value;
                            });
                            checkModified();
                          },
                        ),
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
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
                        : ((initProfNames.isEmpty)
                            ? const Text('Loading...')
                            : const Text(
                                'None',
                                style: TextStyle(color: Colors.red),
                              )),
                    trailing: ProfsSelect(
                      useTextField: false,
                      parentProfPrefixes: localCourse.profs,
                      updatePrefixes: (profModels) {
                        setState(() {
                          localCourse.profs =
                              profModels.map((e) => e.email_prefix).toList();
                          profNames = profModels.map((e) => e.name).toList();
                          if ((const ListEquality())
                              .equals(localCourse.profs, widget.course.profs)) {
                            initProfNames.clear();
                            initProfNames.addAll(profNames);
                          }
                        });
                        checkModified();
                      },
                    ),
                  ),
                ),
                ListTile(
                  visualDensity: const VisualDensity(
                      vertical: VisualDensity.minimumDensity),
                  titleTextStyle: Theme.of(context).textTheme.labelMedium,
                  subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
                  title: SizeTransition(
                    sizeFactor: _animation,
                    axis: Axis.vertical,
                    axisAlignment: 1,
                    child: const Text('Description:'),
                  ),
                  subtitle: Text(localCourse.description),
                  trailing: SizedBox(
                    width: 50,
                    child: SizeTransition(
                      sizeFactor: _animation,
                      axis: Axis.vertical,
                      axisAlignment: 1,
                      child: IconButton(
                        onPressed: () => EditCourseCard.showTextEditor(
                          context: context,
                          fieldName: 'Description',
                          fieldInitValue: localCourse.description,
                          fieldMaxLines: 3,
                          onSubmit: (value) {
                            setState(() {
                              localCourse.description = value;
                            });
                            checkModified();
                          },
                        ),
                        icon: const Icon(Icons.edit),
                      ),
                    ),
                  ),
                ),
                SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: (!saving && modified) ? reset : null,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: (!saving &&
                                modified &&
                                localCourse.profs.isNotEmpty)
                            ? () async {
                                setState(() {
                                  saving = true;
                                });
                                var response = await CourseApiController()
                                    .updateCourse(
                                        widget.course.course_id, localCourse);
                                if (response['message'] != null) {
                                  SchedulerBinding.instance
                                      .addPostFrameCallback((timeStamp) {
                                    scaffoldMessenger.hideCurrentSnackBar();
                                    scaffoldMessenger.showSnackBar(SnackBar(
                                        content: Text(
                                            response['message'] as String)));
                                    if (response['status'] == 200) {
                                      widget.onRefresh();
                                      widget.refreshCourses();
                                    }
                                  });
                                }
                              }
                            : null,
                        child: (saving)
                            ? SizedBox(
                                height:
                                    Theme.of(context).buttonTheme.height - 15,
                                width:
                                    Theme.of(context).buttonTheme.height - 15,
                                child: LoadingIndicator(
                                  indicatorType: Indicator.lineScale,
                                  colors: [
                                    Theme.of(context).colorScheme.primary
                                  ],
                                  strokeWidth: 4.0,
                                  pathBackgroundColor: Colors.black45,
                                ),
                              )
                            : const Row(
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: 10),
                                  Text('Save'),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class CourseDeleteDialog extends StatefulWidget {
  const CourseDeleteDialog({
    super.key,
    required this.courseId,
    required this.popUntil,
    required this.onDelete,
  });

  final String courseId;
  final String popUntil;
  final Function onDelete;

  @override
  State<CourseDeleteDialog> createState() => _CourseDeleteDialogState();
}

class _CourseDeleteDialogState extends State<CourseDeleteDialog> {
  late Future deleteFuture;
  var deleting = false;

  @override
  void initState() {
    deleteFuture = Future.delayed(const Duration(milliseconds: 1));
    super.initState();
  }

  @override
  void dispose() {
    deleteFuture.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete this course permanently?',
              style: Theme.of(context).textTheme.bodyLarge,
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
                  onPressed: (deleting)
                      ? null
                      : () {
                          setState(() {
                            deleting = true;
                            deleteFuture = CourseApiController()
                                .deleteCourse(widget.courseId);
                            deleteFuture.then((value) {
                              if (value != null) {
                                SchedulerBinding.instance
                                    .addPostFrameCallback((timeStamp) {
                                  scaffoldMessenger.hideCurrentSnackBar();
                                  scaffoldMessenger.showSnackBar(SnackBar(
                                      content:
                                          Text(value['message'] as String)));
                                  if (value['status'] == 200) {
                                    widget.onDelete();
                                    if (widget.popUntil.isNotEmpty) {
                                      Navigator.of(context).popUntil(
                                          ModalRoute.withName("/profDash"));
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                });
                              }
                            });
                          });
                        },
                  child: (deleting)
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
                            Icon(Icons.delete_forever),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                ),
                const SizedBox(width: 15),
                FilledButton(
                  onPressed: (deleting)
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
