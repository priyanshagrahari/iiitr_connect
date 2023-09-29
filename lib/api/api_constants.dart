class ApiConstants {
  final String host = "http://10.0.2.2:5000";
  final Endpoints endpoints = Endpoints();
}

class Endpoints {
  final String genOtp = "/genotp";
  final String login = "/login";
  final String verify = "/verify";
}