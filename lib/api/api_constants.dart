class ApiConstants {
  static const String host = "https://natural-naturally-iguana.ngrok-free.app";
}

class UserEndpoints {
  static const prefix = "/users";
  static const genOtp = "/genotp";
  static const login = "/login";
  static const verify = "/verify";

  static String get genOtpUrl => (ApiConstants.host + prefix + genOtp);
  static String get loginUrl => (ApiConstants.host + prefix + login);
  static String get verifyUrl => (ApiConstants.host + prefix + verify);
}

class ProfessorEndpoints {
  static const prefix = "/professors";

  static String getProfessorUrl(String profPrefix) =>
      ("${ApiConstants.host}$prefix/$profPrefix");
}

class StudentEndpoints {
  static const prefix = "/students";
  static const createOne = "/create";
  static const getOneOrAll = "/get";
  static const updateOne = "/update";
  static const delete = "/delete";

  static String getStudentUrl(String rollNum) =>
      ("${ApiConstants.host}$prefix$getOneOrAll/$rollNum");
}

class EncodingEndpoints {
  static const prefix = "/encodings";
  static const student = "/student";
  static const lecture = "/lecture";

  static String uploadStudentPhotoUrl(String rollNum) =>
      ("${ApiConstants.host}$prefix$student/$rollNum");
  static String deleteAllStudentEncodingsUrl(String rollNum) =>
      ("${ApiConstants.host}$prefix$student/$rollNum");
  static String getNumEncodingsUrl(String rollNum) =>
      ("${ApiConstants.host}$prefix$student/$rollNum");
  static String uploadClassPhotoUrl(String lectureId) =>
      ("${ApiConstants.host}$prefix$lecture/$lectureId");
}

class CourseEndpoints {
  static const prefix = "/courses";
  static const getOne = "/get";
  static const createOne = "/create";
  static const updateOne = "/update";
  static const deleteOne = "/delete";
  static const getProfsCourses = "/prof";
  static const getStudentsCourses = "/stud";
  static const reg = "/reg";
  static const numReg = "/numreg";

  static String get createCourseUrl => (ApiConstants.host + prefix + createOne);
  static String getCourseUrl(String courseId) =>
      ("${ApiConstants.host}$prefix$getOne/$courseId");
  static String updateCourseUrl(String courseId) =>
      ("${ApiConstants.host}$prefix$updateOne/$courseId");
  static String deleteCourseUrl(String courseId) =>
      ("${ApiConstants.host}$prefix$deleteOne/$courseId");
  static String getProfessorCoursesUrl(String profPrefix) =>
      ("${ApiConstants.host}$prefix$getProfsCourses/$profPrefix");
}

class LectureEndpoints {
  static const prefix = "/lectures";
  static const createOne = "/create";
  static const getLecture = "/get";
  static const getNCourse = "/course";
  static const update = "/update";
  static const delete = "/delete";

  static String get createLectureUrl =>
      (ApiConstants.host + prefix + createOne);
  static String getLectureUrl(String lectureId) =>
      ('${ApiConstants.host}$prefix$getLecture/$lectureId');
  static String getNCourseLecturesUrl(String courseId, int n) =>
      ('${ApiConstants.host}$prefix$getNCourse/$courseId/$n');
  static String updateLectureUrl(String lectureId) =>
      ('${ApiConstants.host}$prefix$update/$lectureId');
  static String deleteLectureUrl(String lectureId) =>
      ('${ApiConstants.host}$prefix$delete/$lectureId');
}

class RegistrationEndpoints {
  static const prefix = "/registrations";
  static const getAvaRegCourses = "/avareg";
  static const toggleCourseReg = "/reg";
  static const getStudCourses = "/stud";
  static const getNumRegStud = "/numreg";
  static const getCourseStuds = "/cour";

  static String get toggleCourseRegUrl =>
      (ApiConstants.host + prefix + toggleCourseReg);
  static String getNumRegStudUrl(String studentRoll) =>
      ("${ApiConstants.host}$prefix$getNumRegStud/$studentRoll");
  static String getStudCoursesUrl(String studentRoll) =>
      ("${ApiConstants.host}$prefix$getStudCourses/$studentRoll");
  static String getAvailableCourses(String studentRoll) =>
      ("${ApiConstants.host}$prefix$getAvaRegCourses/$studentRoll");
  static String getRegisteredStudents(String courseId) =>
      ("${ApiConstants.host}$prefix$getCourseStuds/$courseId");
}

class AttendancesEndpoints {
  static const prefix = "/attendances";
  static const students = "/students";
  static const course = "/course";

  static String get markAttendanceUrl => ("${ApiConstants.host}$prefix/");
  static String getLectureStudentsUrl(String lectureId) =>
      ("${ApiConstants.host}$prefix$students/$lectureId");
  static String checkStudPresentUrl(String lectureId, String studentRoll) =>
      ("${ApiConstants.host}$prefix$students/$lectureId/$studentRoll");
  static String getCourseAttendanceUrl(String courseId) =>
      ("${ApiConstants.host}$prefix$course/$courseId");
  static String getStudentAttendanceUrl(String courseId, String studentRoll) =>
      ("${ApiConstants.host}$prefix$course/$courseId/$studentRoll");
}
