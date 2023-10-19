// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';

class LectureModel {
  String lecture_id;
  String course_id;
  String lecture_date;
  String description;

  LectureModel({
    required this.lecture_id,
    required this.course_id,
    required this.lecture_date,
    required this.description,
  });

  LectureModel.empty()
      : lecture_id = "",
        course_id = "",
        lecture_date = "",
        description = "";

  LectureModel.fromMap({
    required Map<String, dynamic> map,
  })  : lecture_id = map['lecture_id'] ?? "",
        course_id = map['course_id'],
        lecture_date = map['lecture_date'],
        description = map['description'];

  static Map<String, dynamic> toJson(LectureModel instance) => {
        'lecture_id': instance.lecture_id,
        'course_id': instance.course_id,
        'lecture_date': instance.lecture_date,
        'description': instance.description,
      };
}

class LectureApiController {
  Future<Map<String, dynamic>> createLecture(LectureModel lecture) async {
    var response = await http.post(
      Uri.parse(ApiConstants().createLectureUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
      body: jsonEncode(LectureModel.toJson(lecture)),
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getNLectures(String courseId, int n) async {
    var response = await http.get(
      Uri.parse(ApiConstants().getNCourseLecturesUrl(courseId, n)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getLecture(String lectureId) async {
    var response = await http.get(
      Uri.parse(ApiConstants().getLectureUrl(lectureId)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> updateLecture(String lectureId, LectureModel lecture) async {
    var response = await http.post(
      Uri.parse(ApiConstants().updateLectureUrl(lectureId)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
      body: jsonEncode(LectureModel.toJson(lecture)),
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> deleteLecture(String lectureId) async {
    var response = await http.delete(
      Uri.parse(ApiConstants().deleteLectureUrl(lectureId)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }
}
