class ApiConstants {
  final String host = "https://natural-naturally-iguana.ngrok-free.app";
  final UserEndpoints userEndpoints = UserEndpoints();
  final String studentEndpoint = "/students";
  final professorEndpoints = ProfessorEndpoints();
  final encodingEndpoints = EncodingEndpoints();
  final courseEndpoints = CourseEndpoints();

  String get genOtpUrl => (host + userEndpoints.prefix + userEndpoints.genOtp);
  String get loginUrl => (host + userEndpoints.prefix + userEndpoints.login);
  String get verifyUrl => (host + userEndpoints.prefix + userEndpoints.verify);

  String get uploadStudentPhotoUrl => (host + encodingEndpoints.prefix + encodingEndpoints.student);
  String get deleteStudentPhotoUrl => (host + encodingEndpoints.prefix + encodingEndpoints.student);

  String get getProfessorUrl => (host + professorEndpoints.prefix + professorEndpoints.get);

  String get createCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.createOne);
  String get getCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.get);
  String get updateCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.updateOne);
  String get deleteCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.deleteOne);
  String get getProfessorCoursesUrl => (host + courseEndpoints.prefix + courseEndpoints.getProfsCourses);
}

class UserEndpoints {
  final String prefix = "/users";
  final String genOtp = "/genotp";
  final String login = "/login";
  final String verify = "/verify";
}

class ProfessorEndpoints {
  final String prefix = "/professors";
  final String get = "/";
}

class EncodingEndpoints {
  final String prefix = "/encodings";
  final String student = "/student";
}

class CourseEndpoints {
  final String prefix = "/courses";
  final String get = "/get";
  final String createOne = "/create";
  final String updateOne = "/update";
  final String deleteOne = "/delete";
  final String getProfsCourses = "/prof";
}
