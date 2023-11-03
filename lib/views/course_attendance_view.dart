import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iiitr_connect/api/attendance_api.dart';
import 'package:iiitr_connect/api/course_api.dart';

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
  late Future attendanceFuture;
  late CourseAttendanceData attendanceData;

  @override
  void initState() {
    super.initState();
    attendanceFuture =
        AttendanceApiController().getCourseAttendance(widget.course.course_id);
    attendanceFuture.then((value) {
      attendanceData = value;
      if (attendanceData.status == 200) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Attendance"),
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: max(attendanceData.lectures.length * 100, MediaQuery.of(context).size.width),
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 100,
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
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
                                        ...attendanceData.lectures
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
                              spots: attendanceData.lectures
                                  .mapIndexed((i, e) => FlSpot(i.toDouble(),
                                      ((e.present / attendanceData.reg_students)*100).ceilToDouble()))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Text('Bottom Text')
              ],
            );
          }),
    );
  }
}
