// ignore_for_file: non_constant_identifier_names

import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';

class StudentModel {
  String roll_num;
  String name;

  StudentModel({
    required this.roll_num,
    required this.name,
  });

  StudentModel.empty()
      : roll_num = "",
        name = "";

  StudentModel.fromMap({required Map<String, dynamic> map})
      : roll_num = map['roll_num'],
        name = map['name'];

  static Map<String, dynamic> toJson(StudentModel instance) => {
        'roll_num': instance.roll_num,
        'name': instance.name,
      };
}

class StudentApiController {
  Future<Map<String, dynamic>> getStudent(String rollNum) async {
    var response = await http.get(
      Uri.parse(StudentEndpoints.getStudentUrl(rollNum)),
      headers: {'token': await UserApiController.findToken},
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getByCourse(String courseId) async {
    var response = await http.get(
      Uri.parse(RegistrationEndpoints.getRegisteredStudents(courseId)),
      headers: {'token': await UserApiController.findToken},
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }
}
