import 'dart:typed_data';

import 'package:iiitr_connect/api/api_constants.dart';
import 'package:iiitr_connect/api/user_api.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FaceEncodingsApiController {
  Future<Map<String, dynamic>> uploadFaceData(
      String rollNum, String imagePath) async {
    var imageFile = File(imagePath);
    var stream = http.ByteStream(DelegatingStream(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse(EncodingEndpoints.uploadStudentPhotoUrl(rollNum));
    var request = http.MultipartRequest("POST", uri);
    request.headers.clear();
    request.headers.addEntries({
      MapEntry('token', await UserApiController.findToken),
    });
    var multipartFile = http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));
    request.files.add(multipartFile);
    var response = await request.send();
    var jsonResponse =
        UserApiController.decode(await http.Response.fromStream(response));
    print(jsonResponse);
    return jsonResponse;
  }

  static Future bakeRotation(String path) async {
    String newPath = path;
    if (path.contains('heif') || path.contains('heic')) {
      // convert to jpg
      newPath = path.replaceAll(RegExp(r'heif|heic'), 'jpg');
      var result = await FlutterImageCompress.compressAndGetFile(path, newPath, format: CompressFormat.jpeg, quality: 100);
      print('conversion to jpeg was ${result != null ? 'successful' : 'unsuccessful'}');
    }
    Uint8List imgBytes = await File(newPath).readAsBytes();
    final img.Image capturedImage =
        img.decodeImage(imgBytes)!;
    final img.Image orientedImage = img.bakeOrientation(capturedImage);
    await File(path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  Future<Map<String, dynamic>> getNumEncodings(String rollNum) async {
    var response = await http.get(
      Uri.parse(EncodingEndpoints.getNumEncodingsUrl(rollNum)),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> deleteEncodings(String rollNum) async {
    var response = await http.delete(
      Uri.parse(EncodingEndpoints.getNumEncodingsUrl(rollNum)),
      headers: <String, String>{
        'token': await UserApiController.findToken,
      },
    );
    var jsonResponse = UserApiController.decode(response);
    print(jsonResponse);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> uploadClassPhoto(
      String lectureId, String imagePath) async {
    await bakeRotation(imagePath);
    var imageFile = File(imagePath);
    var stream = http.ByteStream(DelegatingStream(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse(EncodingEndpoints.uploadClassPhotoUrl(lectureId));
    var request = http.MultipartRequest("POST", uri);
    request.headers.clear();
    request.headers.addEntries({
      MapEntry('token', await UserApiController.findToken),
    });
    var multipartFile = http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));
    request.files.add(multipartFile);
    var response = await request.send();
    var jsonResponse =
        UserApiController.decode(await http.Response.fromStream(response));
    print(jsonResponse);
    return jsonResponse;
  }
}
