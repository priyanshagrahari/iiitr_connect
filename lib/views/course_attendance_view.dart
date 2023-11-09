import 'dart:math';

import 'package:collection/collection.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/attendance_api.dart';
import 'package:iiitr_connect/api/course_api.dart';
import 'package:iiitr_connect/api/student_api.dart';
import 'package:iiitr_connect/views/prof_course_view.dart';
import 'package:iiitr_connect/views/stud_course_view.dart';
import 'package:intl/intl.dart';

class CourseAttendanceView extends StatefulWidget {
  const CourseAttendanceView({
    super.key,
    required this.course,
  });

  final CourseModel course;

  @override
  State<CourseAttendanceView> createState() => _CourseAttendanceViewState();
}

class _CourseAttendanceViewState extends State<CourseAttendanceView> {
  late Future attendanceChartFuture;
  late CourseAttendanceData attendanceChartData;

  late Future attendanceTableFuture;
  late List<StudentModel> regStudents;
  late Map<String, List<String>> lectureStudentRolls;
  bool sendingEmail = false;

  var pageController = PageController();
  var fromDateController = TextEditingController();
  var toDateController = TextEditingController();
  var attenFilterController = TextEditingController();
  var attenDropdownController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;
  List<String>? filteredLectureIds;
  bool? lessThanPctg = false;
  double? attendanceFilter;

  @override
  void initState() {
    super.initState();
    attendanceChartFuture =
        AttendanceApiController().getCourseAttendance(widget.course.course_id);
    attendanceChartFuture.then((value) {
      if (!mounted) return;
      setState(() {
        attendanceChartData = value;
      });
      attendanceTableFuture = fetchTableData();
    });
  }

  Future<void> fetchTableData() async {
    var regResp =
        await StudentApiController().getByCourse(widget.course.course_id);
    if (!mounted) return;
    if (regResp['status'] == 200) {
      var localList = List<StudentModel>.empty(growable: true);
      for (var registration in regResp['registrations']) {
        localList.add(StudentModel.fromMap(map: registration['student']));
      }
      setState(() {
        regStudents = localList;
      });
    } else {
      setState(() {
        regStudents = [];
      });
    }
    var localLecStudents = <String, List<String>>{};
    for (var lecture
        in attendanceChartData.lectures.where((element) => element.marked)) {
      var lecResp = await AttendanceApiController()
          .getLectureAttendance(lecture.lecture_id);
      if (!mounted) return;
      if (lecResp['status'] == 200) {
        List<String> presentRollNums = (lecResp['students'] as List<dynamic>)
            .map((e) => e['roll_num'] as String)
            .toList();
        localLecStudents[lecture.lecture_id] = presentRollNums;
      }
    }
    if (!mounted) return;
    setState(() {
      lectureStudentRolls = localLecStudents;
    });
  }

  void applyLectureFilter() {
    if (fromDate != null || toDate != null) {
      setState(() {
        filteredLectureIds = attendanceChartData.lectures
            .where((element) {
              if (!element.marked) return false;
              var fromResult = true;
              var toResult = true;
              if (fromDate != null &&
                  (DateFormat("yyyy-MM-dd")
                      .parse(element.lecture_date)
                      .isBefore(fromDate!))) {
                fromResult = false;
              }
              if (toDate != null &&
                  (DateFormat("yyyy-MM-dd")
                      .parse(element.lecture_date)
                      .isAfter(toDate!))) {
                toResult = false;
              }
              return fromResult && toResult;
            })
            .map((e) => e.lecture_id)
            .toList();
      });
    } else {
      setState(() {
        filteredLectureIds = null;
      });
    }
  }

  List<DataColumn> getTableColumns() {
    var cols = <DataColumn>[];
    cols.add(const DataColumn2(
      label: Text('Roll Num'),
      fixedWidth: 100,
    ));
    cols.add(const DataColumn2(
      label: Text('Student Name'),
      fixedWidth: 200,
    ));
    cols.add(const DataColumn2(
      label: Text('%'),
      fixedWidth: 120,
      numeric: true,
    ));
    cols.addAll(attendanceChartData.lectures.reversed
        .where((element) => (element.marked &&
            ((filteredLectureIds != null)
                ? filteredLectureIds!.contains(element.lecture_id)
                : true)))
        .map((e) => DataColumn2(
              label: Text(e.lecture_date),
              fixedWidth: 140,
            )));
    return cols;
  }

  double getStudentAttendancePctg(String rollNum) {
    var totalCount =
        attendanceChartData.lectures.where((element) => element.marked).length;
    var presentCount = attendanceChartData.lectures
        .where((e) =>
            (e.marked && lectureStudentRolls[e.lecture_id]!.contains(rollNum)))
        .length;
    if (presentCount == 0 && totalCount == 0) {
      totalCount = 1;
    }
    return (presentCount / totalCount * 100).ceilToDouble();
  }

  List<DataRow> getTableRows() {
    var rows = <DataRow>[];
    rows = regStudents
        .where((element) => ((attendanceFilter == null)
            ? true
            : ((lessThanPctg != null)
                ? ((lessThanPctg!)
                    ? getStudentAttendancePctg(element.roll_num) <=
                        attendanceFilter!
                    : getStudentAttendancePctg(element.roll_num) >=
                        attendanceFilter!)
                : getStudentAttendancePctg(element.roll_num) ==
                    attendanceFilter!)))
        .mapIndexed((index, element) {
      var cells = <DataCell>[];
      cells.add(DataCell(Text(element.roll_num)));
      cells.add(DataCell(Text(element.name)));
      cells.add(DataCell(GestureDetector(
        child: Text('${getStudentAttendancePctg(element.roll_num)} %'),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return StudentAttendancePieChartDialog(
                rollNum: element.roll_num,
                courseId: widget.course.course_id,
                courseName: widget.course.name,
              );
            },
          );
        },
      )));
      cells.addAll(attendanceChartData.lectures.reversed
          .where((element) => (element.marked &&
              ((filteredLectureIds != null)
                  ? filteredLectureIds!.contains(element.lecture_id)
                  : true)))
          .map((e) {
        bool present =
            lectureStudentRolls[e.lecture_id]!.contains(element.roll_num);
        return DataCell(Text(
          (present) ? 'Present' : 'Absent',
          style: TextStyle(
            color: (present) ? Colors.green : Colors.red,
          ),
        ));
      }));
      return DataRow(cells: cells);
    }).toList();
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Attendance"),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: attendanceChartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: <Widget>[
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                showCursor: false,
                                enableInteractiveSelection: false,
                                controller: fromDateController,
                                decoration: InputDecoration(
                                  labelText: 'From Date',
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onTap: () async {
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                  var localFromDate =
                                      await EditCourseCard.showCalendar(
                                    context: context,
                                    calendarInitValue: fromDateController.text,
                                    lastDateString: toDateController.text,
                                    onSubmit: (value) {
                                      fromDateController.text = value;
                                    },
                                  );
                                  setState(() {
                                    fromDate = localFromDate;
                                    applyLectureFilter();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                showCursor: false,
                                enableInteractiveSelection: false,
                                controller: toDateController,
                                decoration: InputDecoration(
                                  labelText: 'To Date',
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onTap: () async {
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                  var localToDate =
                                      await EditCourseCard.showCalendar(
                                    context: context,
                                    calendarInitValue: toDateController.text,
                                    firstDateString: fromDateController.text,
                                    onSubmit: (value) {
                                      toDateController.text = value;
                                    },
                                  );
                                  setState(() {
                                    toDate = localToDate;
                                    applyLectureFilter();
                                  });
                                },
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width:
                                  (toDate != null || fromDate != null) ? 50 : 0,
                              child: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  fromDateController.clear();
                                  toDateController.clear();
                                  Future.delayed(
                                          const Duration(milliseconds: 100))
                                      .then((value) {
                                    setState(() {
                                      fromDate = null;
                                      toDate = null;
                                      applyLectureFilter();
                                    });
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: attenFilterController,
                                decoration: InputDecoration(
                                  labelText: 'Filter by Attendance %',
                                  suffixIcon: DropdownMenu(
                                    controller: attenDropdownController,
                                    enableSearch: false,
                                    inputDecorationTheme:
                                        const InputDecorationTheme(
                                      contentPadding: EdgeInsets.all(0),
                                      border: InputBorder.none,
                                      constraints:
                                          BoxConstraints(maxHeight: 35),
                                    ),
                                    initialSelection: lessThanPctg,
                                    width: 75,
                                    dropdownMenuEntries: const <DropdownMenuEntry>[
                                      DropdownMenuEntry(
                                        value: false,
                                        label: '>=',
                                      ),
                                      DropdownMenuEntry(
                                        value: true,
                                        label: '<=',
                                      ),
                                      DropdownMenuEntry(
                                        value: null,
                                        label: '==',
                                      ),
                                    ],
                                    onSelected: (value) {
                                      setState(() {
                                        lessThanPctg = value;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onSubmitted: (value) {
                                  double? p = double.tryParse(value);
                                  if (p != null) {
                                    setState(() {
                                      attendanceFilter = p;
                                    });
                                  } else {
                                    setState(() {
                                      attendanceFilter = null;
                                    });
                                    attenFilterController.clear();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                        future: attendanceTableFuture,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height - 500,
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(30.0),
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      Text(
                                          'This might take some time, please wait...'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          return DataTable2(
                            fixedLeftColumns: 1,
                            headingTextStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                            minWidth: 150 +
                                230 +
                                130 +
                                min(
                                    lectureStudentRolls.keys.length * 150,
                                    (filteredLectureIds != null)
                                        ? (filteredLectureIds!.length * 150)
                                        : double.infinity),
                            columns: getTableColumns(),
                            rows: getTableRows(),
                          );
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.email),
                          label: const Text('Send to Email'),
                          onPressed: (sendingEmail)
                              ? null
                              : () async {
                                  setState(() {
                                    sendingEmail = true;
                                  });
                                  SchedulerBinding.instance
                                      .addPostFrameCallback((timeStamp) {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Sending attendance sheet to email...')));
                                  });
                                  var response = await AttendanceApiController()
                                      .sendAttendanceSheet(
                                          widget.course.course_id);
                                  if (response['message'] != null) {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback((timeStamp) {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content:
                                                  Text(response['message'])));
                                    });
                                  }
                                  if (!mounted) return;
                                  setState(() {
                                    sendingEmail = false;
                                  });
                                },
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.show_chart),
                          label: const Text('View Chart'),
                          onPressed: () {
                            pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: max(attendanceChartData.lectures.length * 75,
                            MediaQuery.of(context).size.width),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                drawBelowEverything: true,
                                axisNameSize: 55,
                                axisNameWidget: Text('Lectures'),
                              ),
                              leftTitles: const AxisTitles(
                                drawBelowEverything: false,
                                axisNameSize: 50,
                                axisNameWidget: Text("Attendance %"),
                              ),
                              bottomTitles: AxisTitles(
                                drawBelowEverything: false,
                                axisNameSize: 100,
                                axisNameWidget: Row(
                                  children: [
                                    const SizedBox(width: 40),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ...attendanceChartData.lectures
                                              .where(
                                                  (element) => element.marked)
                                              .map((e) => RotatedBox(
                                                    quarterTurns: 3,
                                                    child: Text(e.lecture_date),
                                                  ))
                                              .toList(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 35),
                                  ],
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                color: Colors.green,
                                spots: attendanceChartData.lectures
                                    .where((element) => element.marked)
                                    .mapIndexed((i, e) => FlSpot(
                                        i.toDouble(),
                                        ((e.present /
                                                    attendanceChartData
                                                        .reg_students) *
                                                100)
                                            .ceilToDouble()))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('View Table'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
