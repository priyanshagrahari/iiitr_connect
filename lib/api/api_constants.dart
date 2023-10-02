class ApiConstants {
  final String host = "http://localhost:5000";
  final UserEndpoints userEndpoints = UserEndpoints();
  final String studentEndpoint = "/students";
}

class UserEndpoints {
  final String genOtp = "/users/genotp";
  final String login = "/users/login";
  final String verify = "/users/verify";
}
