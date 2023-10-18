import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class FaceEncodingsApiController {
  Future<Map<String, dynamic>> uploadFaceData(String rollNum, String imagePath) async {
    var imageFile = File(imagePath);
    var stream = http.ByteStream(DelegatingStream(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse("${ApiConstants().uploadStudentPhotoUrl}/$rollNum");
    print('sending request to $uri');
    var request = http.MultipartRequest("POST", uri);
    request.headers.clear();
    request.headers.addEntries({
      MapEntry('token', await UserApiController.findToken),
    });
    var multipartFile = http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));
    request.files.add(multipartFile);

    var response = await request.send();
    var jsonResponse = UserApiController.decode(await http.Response.fromStream(response));
    print(jsonResponse);
    return jsonResponse;
  }

  static bakeRotation(String path) async {
    final img.Image capturedImage = img.decodeImage(await File(path).readAsBytes())!;
    final img.Image orientedImage = img.bakeOrientation(capturedImage);
    await File(path).writeAsBytes(img.encodeJpg(orientedImage));
  }
}
