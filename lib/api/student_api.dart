import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:iiitr_connect/api/api_constants.dart';

class StudentApiController {
  Map<String, dynamic> decode(http.Response response) {
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    jsonResponse['status'] = response.statusCode;
    return jsonResponse;
  }

  Future<Map<String, dynamic>> getData(String rollNum) async {
    var response = await http.get(
      Uri.parse('${ApiConstants().host}${ApiConstants().studentEndpoint}/$rollNum'),
    );
    print(response.body);
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    jsonResponse['status'] = response.statusCode;
    return jsonResponse;
  }
}
