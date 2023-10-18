import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:iiitr_connect/api/professor_api.dart';
import 'package:iiitr_connect/views/course_view.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AddCourseButton extends StatefulWidget {
  const AddCourseButton({
    super.key,
    required this.profPrefix,
    required this.reloadCourses,
  });

  final String profPrefix;
  final Function reloadCourses;

  @override
  State<AddCourseButton> createState() => _AddCourseButtonState();
}

class _AddCourseButtonState extends State<AddCourseButton> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('Add course'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return AddCourseForm(
                profPrefix: widget.profPrefix,
                reloadCourses: widget.reloadCourses,
              );
            },
          ),
        );
      },
    );
  }
}

class AddCourseForm extends StatefulWidget {
  const AddCourseForm({
    super.key,
    required this.profPrefix,
    required this.reloadCourses,
  });

  final String profPrefix;
  final Function reloadCourses;

  @override
  State<AddCourseForm> createState() => _AddCourseFormState();
}

enum AcceptingRegistrations { yes, no }

class _AddCourseFormState extends State<AddCourseForm> {
  final _formKey = GlobalKey<FormState>();

  var courseCode = "";
  var courseName = "";
  var dates = ["", ""];
  var profPrefixes = <String>[];
  var acceptingReg = AcceptingRegistrations.yes;
  var description = "";

  final beginDateController = TextEditingController();
  final endDateController = TextEditingController();

  var saving = false;

  @override
  void dispose() {
    beginDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  void updatePrefixes(List<ProfessorModel> profs) {
    setState(() {
      profPrefixes = profs.map((e) => e.email_prefix).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            onWillPop: () async {
              beginDateController.clear();
              endDateController.clear();
              setState(() {
                courseCode = "";
                courseName = "";
                dates = ["", ""];
                acceptingReg = AcceptingRegistrations.yes;
                description = "";
              });
              return true;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Registrations: ",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SegmentedButton(
                        segments: const <ButtonSegment<AcceptingRegistrations>>[
                          ButtonSegment<AcceptingRegistrations>(
                            value: AcceptingRegistrations.yes,
                            label: Text("Open"),
                          ),
                          ButtonSegment<AcceptingRegistrations>(
                            value: AcceptingRegistrations.no,
                            label: Text("Closed"),
                          ),
                        ],
                        selected: <AcceptingRegistrations>{acceptingReg},
                        onSelectionChanged: (p0) {
                          setState(() {
                            acceptingReg = p0.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                    suffixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      setState(() {
                        courseCode = value.trim();
                      });
                      return null;
                    } else {
                      return "Please enter a course code";
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    suffixIcon: Icon(Icons.abc),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      setState(() {
                        courseName = value.trim();
                      });
                      return null;
                    } else {
                      return "Please enter a course name";
                    }
                  },
                ),
                TextFormField(
                  showCursor: false,
                  enableInteractiveSelection: false,
                  controller: beginDateController,
                  decoration: const InputDecoration(
                    labelText: 'Begin Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select the begin date";
                    }
                    return null;
                  },
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    EditCourseCard.showCalendar(
                      context: context,
                      calendarInitValue: beginDateController.text,
                      lastDateString: endDateController.text,
                      onSubmit: (value) {
                        setState(() {
                          dates[0] = value;
                        });
                        beginDateController.text = value;
                      },
                    );
                  },
                ),
                TextFormField(
                  showCursor: false,
                  enableInteractiveSelection: false,
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    EditCourseCard.showCalendar(
                      context: context,
                      calendarInitValue: endDateController.text,
                      firstDateString: beginDateController.text,
                      onSubmit: (value) {
                        setState(() {
                          dates[1] = value;
                        });
                        endDateController.text = value;
                      },
                    );
                  },
                ),
                ProfsSelect(
                  currentProfPrefix: widget.profPrefix,
                  updatePrefixes: updatePrefixes,
                  parentProfPrefixes: profPrefixes,
                ),
                TextFormField(
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    suffixIcon: Icon(Icons.abc),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      setState(() {
                        description = value.trim();
                      });
                    }
                    return null;
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
                            var response = await CourseApiController()
                                .createCourse(CourseModel(
                                    course_id: "",
                                    course_code: courseCode,
                                    name: courseName,
                                    begin_date: dates[0],
                                    end_date: dates[1],
                                    accepting_reg: acceptingReg ==
                                        AcceptingRegistrations.yes,
                                    description: description,
                                    profs: profPrefixes));
                            if (response['message'] != null) {
                              SchedulerBinding.instance.addPostFrameCallback(
                                (timeStamp) {
                                  scaffoldMessenger.hideCurrentSnackBar();
                                  scaffoldMessenger.showSnackBar(SnackBar(
                                      content:
                                          Text(response['message'] as String)));
                                  if (response['status'] == 201 ||
                                      response['status'] == 200) {
                                    widget.reloadCourses();
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            }
                            if (response['status'] == 400) {
                              // KEEP EDITING
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
      ),
    );
  }
}

// ignore: must_be_immutable
class ProfsSelect extends StatefulWidget {
  ProfsSelect({
    super.key,
    required this.currentProfPrefix,
    required this.updatePrefixes,
    required this.parentProfPrefixes,
    this.useTextField = true,
  });

  final String currentProfPrefix;
  final Function(List<ProfessorModel>) updatePrefixes;
  bool useTextField;
  List<String> parentProfPrefixes;

  @override
  State<ProfsSelect> createState() => _ProfsSelectState();
}

class _ProfsSelectState extends State<ProfsSelect> {
  late Future<Map<String, dynamic>> profsFuture;
  var multiSelectItems =
      List<MultiSelectItem<ProfessorModel>>.empty(growable: true);
  var namesTextController = TextEditingController();

  @override
  void initState() {
    getData();
    super.initState();
  }

  void getData() {
    profsFuture = ProfessorApiController().getData('all');
    profsFuture.then((value) => processResponse(value));
  }

  @override
  void dispose() {
    namesTextController.dispose();
    super.dispose();
  }

  void processResponse(Map<String, dynamic> data) {
    var profDataList = data['professors'] as List<dynamic>;
    var localProfsList =
        List<MultiSelectItem<ProfessorModel>>.empty(growable: true);
    var localSelected = List<ProfessorModel>.empty(growable: true);
    for (var e in profDataList) {
      var modelItem =
          ProfessorModel(email_prefix: e['email_prefix'], name: e['name']);
      var selItem = MultiSelectItem(modelItem, modelItem.name);
      if (widget.parentProfPrefixes.contains(e['email_prefix'])) {
        localSelected.add(modelItem);
      }
      localProfsList.add(selItem);
    }
    if (mounted) {
      setState(() {
        multiSelectItems = localProfsList;
      });
      if (!widget.useTextField) {
        widget.updatePrefixes(localSelected);
      }
    }
  }

  void showMultiSelect(BuildContext context) async {
    var localSelected = List<ProfessorModel>.empty(growable: true);
    for (var e in multiSelectItems) {
      if (widget.parentProfPrefixes.contains(e.value.email_prefix)) {
        localSelected.add(e.value);
      }
    }

    await showModalBottomSheet(
      isScrollControlled: true, // required for min/max child size
      context: context,
      builder: (ctx) {
        return MultiSelectBottomSheet<ProfessorModel>(
          title: Text(
            '   Professors',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          confirmText: const Text('SAVE'),
          searchable: true,
          listType: MultiSelectListType.CHIP,
          items: multiSelectItems,
          initialValue: localSelected,
          initialChildSize: 0.5,
          maxChildSize: 1,
          selectedColor: Theme.of(context).colorScheme.primary,
          selectedItemsTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onConfirm: (values) {
            widget.updatePrefixes(values);
            if (widget.useTextField) {
              namesTextController.text =
                  values.map((e) => e.name).toList().join(', ');
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useTextField) {
      return TextFormField(
        controller: namesTextController,
        showCursor: false,
        enableInteractiveSelection: false,
        decoration: const InputDecoration(
          labelText: 'Professors',
          suffixIcon: Icon(Icons.person_add),
        ),
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          showMultiSelect(context);
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please select at least one professor";
          }
          return null;
        },
      );
    } else {
      return IconButton(
        onPressed: () {
          showMultiSelect(context);
        },
        icon: const Icon(Icons.person_add),
      );
    }
  }
}
