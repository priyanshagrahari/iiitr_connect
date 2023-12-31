import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:collection/collection.dart';
import 'package:iiitr_connect/api/lecture_api.dart';
import 'package:iiitr_connect/views/add_course_button.dart';
import 'package:iiitr_connect/views/add_lecture_form.dart';
import 'package:iiitr_connect/views/all_lectures.dart';
import 'package:iiitr_connect/views/course_attendance_view.dart';
import 'package:iiitr_connect/views/course_students_view.dart';
import 'package:iiitr_connect/views/mark_attendance.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';

class ProfCourseView extends StatefulWidget {
  const ProfCourseView({
    super.key,
    required this.courseId,
    required this.refreshCourses,
  });

  final String courseId;
  final Function refreshCourses;

  @override
  State<ProfCourseView> createState() => _ProfCourseViewState();
}

class _ProfCourseViewState extends State<ProfCourseView> {
  late Future courseFuture;
  CourseModel course = CourseModel.empty();

  int recentWindowSize = 5;
  late Future recentLecturesFuture;
  List<LectureModel> recentLectures = [];

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
    }
    if (what == 0 || what == 2) {
      recentLecturesFuture = LectureApiController()
          .getNLectures(widget.courseId, recentWindowSize);
      recentLecturesFuture.then((value) {
        if (!mounted) return;
        if (value['lectures'] != null) {
          setState(() {
            recentLectures = (value['lectures'] as List<dynamic>)
                .map((e) => LectureModel.fromMap(map: e))
                .toList();
          });
        } else {
          setState(() {
            recentLectures = [];
          });
        }
      });
    }
  }

  @override
  void dispose() {
    courseFuture.ignore();
    recentLecturesFuture.ignore();
    super.dispose();
  }

  Future onRefresh() async {
    initFutures();
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
                barrierColor: const Color.fromARGB(230, 0, 0, 0),
                builder: (ctx) {
                  return CourseDeleteDialog(
                    courseId: widget.courseId,
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
                              labelString: "Add Lecture",
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
                              iconData: Icons.library_books_outlined,
                              labelString: "All Lectures",
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
                              iconData: Icons.table_chart,
                              labelString: "View Attendance",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return CourseAttendanceView(
                                          course: course);
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder(
                    future: recentLecturesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.data['status'] == 200) {
                          var listTiles = recentLectures.map(
                            (e) {
                              return ProfLectureCard(
                                lectureId: e.lecture_id,
                                onUpdate: () => initFutures(what: 2),
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
                                  style: Theme.of(context).textTheme.titleLarge,
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
                    },
                  )
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class ProfLectureCard extends StatefulWidget {
  const ProfLectureCard({
    super.key,
    required this.lectureId,
    required this.onUpdate,
    required this.onDelete,
  });

  final String lectureId;
  final Function onUpdate;
  final Function onDelete;

  @override
  State<ProfLectureCard> createState() => _ProfLectureCardState();
}

class _ProfLectureCardState extends State<ProfLectureCard>
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

    return Card(
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
                          trailing: (lecture.atten_marked)
                              ? const Icon(Icons.checklist)
                              : null,
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
                                onPressed: () => EditCourseCard.showTextEditor(
                                  context: context,
                                  fieldName: "Description",
                                  fieldInitValue: lecture.description,
                                  fieldMaxLines: 5,
                                  onSubmit: (value) {
                                    // SAVE
                                    lecture.description = value;
                                    lectureFuture = LectureApiController()
                                        .updateLecture(
                                            lecture.lecture_id, lecture);
                                    lectureFuture.then((value) {
                                      if (mounted && value['status'] == 200) {
                                        setState(() {
                                          lecture =
                                              LectureModel.fromMap(map: value);
                                        });
                                        widget.onUpdate();
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((timeStamp) {
                                          scaffoldMessenger
                                              .hideCurrentSnackBar();
                                          scaffoldMessenger.showSnackBar(
                                              SnackBar(
                                                  content: Text(value['message']
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
                              // MARK ATTENDANCE BUTTON
                              child: Row(
                                children: [
                                  const Icon(Icons.bar_chart),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return MarkAttendance(
                                        lecture: lecture,
                                        dateString: formattedDateString(
                                            lecture.lecture_date),
                                        onSaved: widget.onUpdate,
                                      );
                                    },
                                  ),
                                );
                              },
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
                                    // CONFIRM DELETE
                                    onPressed: () async {
                                      _deleteController.reverse();
                                      setState(() {
                                        deleting = true;
                                      });
                                      var response =
                                          await LectureApiController()
                                              .deleteLecture(
                                                  lecture.lecture_id);
                                      if (response['message'] != null) {
                                        SchedulerBinding.instance
                                            .addPostFrameCallback(
                                          (_) {
                                            scaffoldMessenger
                                                .hideCurrentSnackBar();
                                            scaffoldMessenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    response['message']
                                                        as String),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      if (mounted &&
                                          response['status'] == 200) {
                                        widget.onDelete();
                                      } else {
                                        setState(() {
                                          deleting = false;
                                        });
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
    );
  }
}

class ExpandedCardButton extends StatelessWidget {
  const ExpandedCardButton({
    super.key,
    required this.iconData,
    required this.labelString,
    required this.onTap,
  });

  final IconData iconData;
  final String labelString;
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
                  labelString,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
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
      isScrollControlled: true,
      builder: (context) {
        var fieldKey = GlobalKey<FormFieldState>();
        return Wrap(
          children: <Widget>[
            Container(
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
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
                          fieldKey.currentState!.save();
                        },
                        onSaved: (value) {
                          if (fieldKey.currentState!.validate()) {
                            onSubmit(value.toString().trim());
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
                      TextButton(
                        onPressed: () {
                          fieldKey.currentState!.save();
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  static Future<DateTime?> showCalendar({
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
    return picked;
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
                        child: Text("Code: ${widget.course.course_code}"),
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
    required this.onDelete,
  });

  final String courseId;
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
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete this course permanently?',
              style: TextStyle(
                  color: Colors.white70,
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
                                    Navigator.of(context)
                                      ..pop()
                                      ..pop();
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
