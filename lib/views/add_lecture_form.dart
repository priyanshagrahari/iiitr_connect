import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/lecture_api.dart';
import 'package:iiitr_connect/views/course_view.dart';
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

  @override
  void dispose() {
    lectureDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);
    
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
              FilledButton(
                onPressed: (saving)
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _formKey.currentState!.deactivate();
                          setState(() {
                            saving = true;
                          });
                          var response = await LectureApiController()
                              .createLecture(LectureModel(
                                  lecture_id: "",
                                  course_id: widget.courseId,
                                  lecture_date: lectureDate,
                                  description: description));
                          if (response['message'] != null) {
                              SchedulerBinding.instance.addPostFrameCallback(
                                (timeStamp) {
                                  scaffoldMessenger.hideCurrentSnackBar();
                                  scaffoldMessenger.showSnackBar(SnackBar(
                                      content:
                                          Text(response['message'] as String)));
                                  if (response['status'] == 201 ||
                                      response['status'] == 200) {
                                    widget.reloadLectures();
                                    Future.delayed(const Duration(milliseconds: 500)).then((value) {
                                      Navigator.pop(context);
                                    });
                                  }
                                },
                              );
                            }
                            if (response['status'] == 400) {
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
                          Text('Submit'),
                        ],
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
