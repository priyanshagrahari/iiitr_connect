// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';

class LectureAttendanceData {
  String lecture_id;
  String lecture_date;
  bool marked;
  int present;
  int absent;

  LectureAttendanceData({
    required this.lecture_id,
    required this.lecture_date,
    required this.marked,
    required this.present,
    required this.absent,
  });
}

class CourseAttendanceData {
  int status;
  int reg_students;
  int total_lectures;
  List<LectureAttendanceData> lectures = [];

  CourseAttendanceData({
    required this.status,
    required this.reg_students,
    required this.total_lectures,
  });
}

class AttendanceApiController {
  Future<Map<String, dynamic>> checkStudPresent(
      String lectureId, String studentRoll) async {
    var response = await http.get(
      Uri.parse(
          AttendancesEndpoints.checkStudPresentUrl(lectureId, studentRoll)),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getLectureAttendance(String lectureId) async {
    var response = await http.get(
      Uri.parse(AttendancesEndpoints.getLectureStudentsUrl(lectureId)),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> markLectureAttendance(
      String lectureId, List<String> regIds) async {
    var response =
        await http.post(Uri.parse(AttendancesEndpoints.markAttendanceUrl),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'token': await UserApiController.findToken,
            },
            body: jsonEncode(<String, dynamic>{
              'lecture_id': lectureId,
              'registration_ids': regIds,
            }));
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<CourseAttendanceData> getCourseAttendance(String courseId) async {
    var response = await http.get(
      Uri.parse(AttendancesEndpoints.getCourseAttendanceUrl(courseId)),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    if (response.statusCode == 200) {
      var data = CourseAttendanceData(
        status: 200,
        reg_students: jsonResponse['reg_students'],
        total_lectures: jsonResponse['total_lectures'],
      );
      for (var lectureMap in jsonResponse['lectures']) {
        data.lectures.add(LectureAttendanceData(
          lecture_id: lectureMap['lecture_id'],
          lecture_date: lectureMap['lecture_date'],
          marked: lectureMap['marked'],
          present: lectureMap['present'],
          absent: lectureMap['absent'],
        ));
      }
      return data;
    }
    return CourseAttendanceData(
      status: response.statusCode,
      reg_students: jsonResponse['reg_students'],
      total_lectures: jsonResponse['total_lectures'],
    );
  }

  Future<Map<String, dynamic>> getStudentCourseAttendance(
      String courseId, String studentRoll) async {
    var response = await http.get(
      Uri.parse(
          AttendancesEndpoints.getStudentAttendanceUrl(courseId, studentRoll)),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> sendAttendanceSheet(String courseId) async {
    var response = await http.get(
      Uri.parse(
          AttendancesEndpoints.sendSheetEmailUrl(courseId)),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }
}
