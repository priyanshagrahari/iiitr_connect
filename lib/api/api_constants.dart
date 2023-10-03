class ApiConstants {
  final String host = "https://iiitr-connect.vercel.app";
  final UserEndpoints userEndpoints = UserEndpoints();
  final String studentEndpoint = "/students";

  String get genOtpUrl => (host + userEndpoints.prefix + userEndpoints.genOtp);
  String get loginUrl => (host + userEndpoints.prefix + userEndpoints.login);
  String get verifyUrl => (host + userEndpoints.prefix + userEndpoints.verify);
}

class UserEndpoints {
  final String prefix = "/users";
  final String genOtp = "/genotp";
  final String login = "/login";
  final String verify = "/verify";
}
