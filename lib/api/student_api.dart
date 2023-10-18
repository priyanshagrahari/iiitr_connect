import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';

class StudentApiController {
  Future<Map<String, dynamic>> getData(String rollNum) async {
    var response = await http.get(
      Uri.parse('${ApiConstants().host}${ApiConstants().studentEndpoint}/$rollNum'),
      headers: {'token' : await UserApiController.findToken}
    );
    print(response.body);
    var jsonResponse = UserApiController.decode(response);
    return jsonResponse;
  }
}
