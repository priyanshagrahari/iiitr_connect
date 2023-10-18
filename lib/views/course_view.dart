import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:collection/collection.dart';
import 'package:iiitr_connect/views/add_course.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';

class CourseView extends StatefulWidget {
  const CourseView({
    super.key,
    required this.profPrefix,
    required this.courseId,
    required this.refreshCourses,
  });

  final String profPrefix;
  final String courseId;
  final Function refreshCourses;

  @override
  State<CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  late Future courseFuture;
  CourseModel course = CourseModel.empty();

  @override
  void initState() {
    courseFuture = CourseApiController().getCourse(courseId: widget.courseId);
    courseFuture.then((value) {
      if (mounted) {
        setState(() {
          course = CourseModel.fromMap(map: value['courses'][0]);
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    courseFuture.ignore();
    super.dispose();
  }

  Future onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 50));
    courseFuture = CourseApiController().getCourse(courseId: widget.courseId);
    courseFuture.then((value) {
      if (mounted) {
        setState(() {
          course = CourseModel.fromMap(map: value['courses'][0]);
        });
      }
    });
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
                      profPrefix: widget.profPrefix,
                      course: course,
                      onRefresh: onRefresh,
                      refreshCourses: widget.refreshCourses,
                    ),
                  ],
                ),
              );
            }
          },
        ));
  }
}

class EditCourseCard extends StatefulWidget {
  const EditCourseCard({
    super.key,
    required this.profPrefix,
    required this.course,
    required this.onRefresh,
    required this.refreshCourses,
  });

  final String profPrefix;
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
                      currentProfPrefix: widget.profPrefix,
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
