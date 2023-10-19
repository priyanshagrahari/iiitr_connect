class ApiConstants {
  final String host = "https://natural-naturally-iguana.ngrok-free.app";
  final UserEndpoints userEndpoints = UserEndpoints();
  final String studentEndpoint = "/students";
  final professorEndpoints = ProfessorEndpoints();
  final encodingEndpoints = EncodingEndpoints();
  final courseEndpoints = CourseEndpoints();
  final lectureEndpoints = LectureEndpoints();

  String get genOtpUrl => (host + userEndpoints.prefix + userEndpoints.genOtp);
  String get loginUrl => (host + userEndpoints.prefix + userEndpoints.login);
  String get verifyUrl => (host + userEndpoints.prefix + userEndpoints.verify);

  String get uploadStudentPhotoUrl => (host + encodingEndpoints.prefix + encodingEndpoints.student);
  String get deleteStudentPhotoUrl => (host + encodingEndpoints.prefix + encodingEndpoints.student);

  String get getProfessorUrl => (host + professorEndpoints.prefix + professorEndpoints.get);

  String get createCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.createOne);
  String get getCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.getLecture);
  String get updateCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.updateOne);
  String get deleteCourseUrl => (host + courseEndpoints.prefix + courseEndpoints.deleteOne);
  String get getProfessorCoursesUrl => (host + courseEndpoints.prefix + courseEndpoints.getProfsCourses);

  String get createLectureUrl => (host + lectureEndpoints.prefix + lectureEndpoints.createOne);
  String getLectureUrl(String lectureId) => ('$host${lectureEndpoints.prefix}${lectureEndpoints.getLecture}/$lectureId');
  String getNCourseLecturesUrl(String courseId, int n) => ('$host${lectureEndpoints.prefix}${lectureEndpoints.getNCourse}/$courseId/$n');
  String updateLectureUrl(String lectureId) => ('$host${lectureEndpoints.prefix}${lectureEndpoints.update}/$lectureId');
  String deleteLectureUrl(String lectureId) => ('$host${lectureEndpoints.prefix}${lectureEndpoints.delete}/$lectureId');
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
  final String getLecture = "/get";
  final String createOne = "/create";
  final String updateOne = "/update";
  final String deleteOne = "/delete";
  final String getProfsCourses = "/prof";
}

class LectureEndpoints {
  final String prefix = "/lectures";
  final String createOne = "/create";
  final String getLecture = "/get";
  final String getNCourse = "/course";
  final String update = "/update";
  final String delete = "/delete";
}
