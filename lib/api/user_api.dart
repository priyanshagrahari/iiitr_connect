import 'dart:convert' as convert;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserApiController {
  Future<String> get findToken async {
    var storage = const FlutterSecureStorage();
    var token = await storage.read(key: "token");
    if (token == null) return "";
    return token;
  }

  Map<String, dynamic> decode(http.Response response) {
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    jsonResponse['status'] = response.statusCode;
    return jsonResponse;
  }

  Future<Map<String, dynamic>> verifyToken() async {
    var token = await findToken;
    if (token != "") {
      var response = await http.post(
        Uri.parse(ApiConstants().verifyUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': token,
        }),
      );
      print(response.body);
      if (response.statusCode == 401) {
        await logout();
      }
      var jsonResponse = decode(response);
      return jsonResponse;
    } else {
      return {'message': 'Please login to continue', 'status': 404};
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    print(Uri.parse(ApiConstants().genOtpUrl));
    var response = await http.post(
      Uri.parse(ApiConstants().genOtpUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'otp': 0
      }),
    );
    print(response.body);
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    jsonResponse['status'] = response.statusCode;
    return jsonResponse;
  }

  Future<Map<String, dynamic>> checkOtp(String email, int otp) async {
    var response = await http.post(
      Uri.parse(ApiConstants().loginUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'otp': otp,
      }),
    );
    print(response.body);
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    jsonResponse['status'] = response.statusCode;
    var storage = const FlutterSecureStorage();
    if (response.statusCode == 200) {
      await storage.write(key: "token", value: jsonResponse['token']);
    } else {
      await storage.write(key: "token", value: null);
    }
    return jsonResponse;
  }

  Future<void> logout() async {
    var storage = const FlutterSecureStorage();
    await storage.write(key: "token", value: null);
  }
}
