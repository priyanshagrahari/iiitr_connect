// ignore_for_file: non_constant_identifier_names

import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';

class ProfessorModel {
  final String email_prefix;
  final String name;

  ProfessorModel({
    required this.email_prefix,
    required this.name,
  });

  @override
  String toString() {
    return "{email_prefix: $email_prefix, name: $name}";
  }
}

class ProfessorApiController {
  Future<Map<String, dynamic>> getData(String emailPrefix) async {
    var response = await http.get(
        Uri.parse(ProfessorEndpoints.getProfessorUrl(emailPrefix)),
        headers: {'token': await UserApiController.findToken});
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }
}
