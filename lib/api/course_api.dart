// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';

class CourseModel {
  String course_id;
  String course_code;
  String name;
  String begin_date;
  String end_date;
  bool accepting_reg;
  String description;
  bool is_running;
  List<String> profs;

  CourseModel({
    required this.course_id,
    required this.course_code,
    required this.name,
    required this.begin_date,
    required this.end_date,
    required this.accepting_reg,
    required this.description,
    required this.is_running,
    required this.profs,
  });

  CourseModel.empty()
      : course_id = "",
        course_code = "",
        name = "",
        begin_date = "",
        end_date = "",
        accepting_reg = false,
        description = "",
        is_running = false,
        profs = [];

  CourseModel.fromMap({
    required Map<String, dynamic> map,
  })  : course_id = map['course_id'] ?? "",
        course_code = map['course_code'],
        name = map['name'],
        begin_date = map['begin_date'],
        end_date = map['end_date'],
        accepting_reg = map['accepting_reg'],
        description = map['description'],
        is_running = map['is_running'] ?? false,
        profs = (map['profs'] != null)
            ? (map['profs'] as List<dynamic>).map((p) => (p as String)).toList()
            : [];

  static Map<String, dynamic> toJson(CourseModel instance) => {
        'course_code': instance.course_code,
        'name': instance.name,
        'begin_date': instance.begin_date,
        'end_date': instance.end_date,
        'accepting_reg': instance.accepting_reg,
        'description': instance.description,
        'profs': instance.profs,
      };
}

class CourseApiController {
  Future<Map<String, dynamic>> getCourse({String? courseId}) async {
    Uri getUri = Uri.parse(CourseEndpoints.getCourseUrl(courseId??'all'));
    var response = await http
        .get(getUri, headers: {'token': await UserApiController.findToken});
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getProfCourses(String emailPrefix) async {
    var response = await http.get(
      Uri.parse(CourseEndpoints.getProfessorCoursesUrl(emailPrefix)),
      headers: {'token': await UserApiController.findToken},
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> createCourse(CourseModel course) async {
    var response = await http.post(
      Uri.parse(CourseEndpoints.createCourseUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
      body: jsonEncode(CourseModel.toJson(course)),
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    var response = await http.delete(
      Uri.parse(CourseEndpoints.deleteCourseUrl(courseId)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> updateCourse(
      String courseId, CourseModel course) async {
    var response = await http.post(
      Uri.parse(CourseEndpoints.updateCourseUrl(courseId)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
      body: jsonEncode(CourseModel.toJson(course)),
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getStudCourses(String rollNum) async {
    var response = await http.get(
      Uri.parse(RegistrationEndpoints.getStudCoursesUrl(rollNum)),
      headers: {'token': await UserApiController.findToken},
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getRegCourses(String studentRoll) async {
    var response = await http.get(
      Uri.parse(RegistrationEndpoints.getAvailableCourses(studentRoll)),
      headers: {'token': await UserApiController.findToken},
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> toggleCourseRegistration(String courseId, String studentRoll) async {
    var url = RegistrationEndpoints.toggleCourseRegUrl;
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
      body: jsonEncode(<String, String>{
        'course_id': courseId,
        'student_roll' : studentRoll
      })
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;    
  }

  Future<Map<String, dynamic>> getNumRegStudents(String courseId) async {
    var url = RegistrationEndpoints.getNumRegStudUrl(courseId);
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }
}
