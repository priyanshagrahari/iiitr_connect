import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/lecture_api.dart';
import 'package:iiitr_connect/views/mark_attendance.dart';
import 'package:iiitr_connect/views/prof_course_view.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';

class AddLectureForm extends StatefulWidget {
  const AddLectureForm({
    super.key,
    required this.courseId,
    required this.reloadLectures,
  });

  final String courseId;
  final Function reloadLectures;

  @override
  State<AddLectureForm> createState() => _AddLectureFormState();
}

class _AddLectureFormState extends State<AddLectureForm> {
  final _formKey = GlobalKey<FormState>();

  var lectureDate = "";
  var description = "";

  final lectureDateController = TextEditingController();

  var saving = false;
  var mark = false;

  @override
  void dispose() {
    lectureDateController.dispose();
    super.dispose();
  }

  Future<LectureModel> saveForm() async {
    var obj = LectureModel(
      lecture_id: "",
      course_id: widget.courseId,
      lecture_date: lectureDate,
      atten_marked: false,
      description: description,
    );
    var response = await LectureApiController().createLecture(obj);
    if (response['message'] != null) {
      SchedulerBinding.instance.addPostFrameCallback(
        (timeStamp) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] as String)));
          if (response['status'] == 201 || response['status'] == 200) {
            obj.lecture_id = response['lecture_id'];
            widget.reloadLectures();
          }
        },
      );
    }
    if (response['status'] == 400) {
      setState(() {
        saving = false;
        mark = false;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return obj;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Lecture'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Form(
          key: _formKey,
          onWillPop: () async {
            // clear all fields
            return true;
          },
          child: Column(
            children: <Widget>[
              TextFormField(
                showCursor: false,
                enableInteractiveSelection: false,
                controller: lectureDateController,
                decoration: const InputDecoration(
                  labelText: 'Lecture Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select the lecture date";
                  }
                  return null;
                },
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  EditCourseCard.showCalendar(
                    context: context,
                    calendarInitValue: lectureDateController.text,
                    onSubmit: (value) {
                      setState(() {
                        lectureDate = value;
                      });
                      lectureDateController.text = value;
                    },
                  );
                },
              ),
              TextFormField(
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  suffixIcon: Icon(Icons.abc),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    setState(() {
                      description = value.trim();
                    });
                    return null;
                  }
                  return "Please enter a description for the lecture";
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: (saving || mark)
                        ? null
                        : () async {
                            setState(() {
                              saving = true;
                            });
                            if (_formKey.currentState!.validate()) {
                              var lecture = await saveForm();
                              if (lecture.lecture_id.isNotEmpty) {
                                Future.delayed(
                                        const Duration(milliseconds: 500))
                                    .then((value) {
                                  Navigator.pop(context);
                                });
                              } else {
                                setState(() {
                                  saving = false;
                                });
                              }
                            }
                          },
                    child: (saving)
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
                              Icon(Icons.post_add),
                              SizedBox(width: 10),
                              Text('Save'),
                            ],
                          ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: (saving || mark)
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                mark = true;
                              });
                              var lecture = await saveForm();
                              if (lecture.lecture_id.isEmpty) {
                                setState(() {
                                  mark = false;
                                });
                              }
                              var dateObj = DateFormat('yyyy-MM-dd')
                                  .parse(lecture.lecture_date);
                              var format = DateFormat('EEEE, dd MMM yyyy');
                              Future.delayed(const Duration(milliseconds: 500))
                                  .then((value) {
                                Navigator.of(context)
                                  ..pop()
                                  ..push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return MarkAttendance(
                                          lecture: lecture,
                                          dateString: format.format(dateObj),
                                          onSaved: widget.reloadLectures,
                                        );
                                      },
                                    ),
                                  );
                              });
                            }
                          },
                    child: (mark)
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
                              Icon(Icons.bar_chart),
                              SizedBox(width: 10),
                              Text('Save & Mark'),
                            ],
                          ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
