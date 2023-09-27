class ApiConstants {
  final String host = "https://localhost:5000";
  final Endpoints endpoints = Endpoints();
}

class Endpoints {
  final String sendOtp = "/genotp";
  final String login = "/login";
  final String verify = "/verify";
}