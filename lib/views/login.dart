import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:iiitr_connect/api/professor_api.dart';
import 'package:iiitr_connect/api/student_api.dart';
import 'package:iiitr_connect/api/user_api.dart';
import 'package:iiitr_connect/views/professor_dash.dart';
import 'package:iiitr_connect/views/student_dash.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Future<Map<String, dynamic>> loginFuture;
  final loginMessageShown = [false];

  @override
  void initState() {
    loginFuture = UserApiController().verifyToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 15,
                  color: Theme.of(context).colorScheme.background,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 80,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            'images/logoSquareWhite.png',
                            width: 150,
                            height: 150,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Text(
                            'IIITR Connect',
                            style: TextStyle(
                              fontSize: 30,
                              fontFamily: 'Mooli',
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          FutureBuilder(
                            future: loginFuture,
                            builder:
                                (BuildContext context, AsyncSnapshot snap) {
                              if (snap.connectionState ==
                                      ConnectionState.done &&
                                  snap.data != null) {
                                if (snap.data['status'] != 404 &&
                                    !loginMessageShown[0]) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                            content:
                                                Text(snap.data['message'])),
                                      );
                                    setState(() {
                                      loginMessageShown[0] = true;
                                    });
                                  });
                                }
                                if (snap.data['status'] == 404 ||
                                    snap.data['status'] == 401) {
                                  return const LoginForm();
                                } else if (snap.data['status'] == 200) {
                                  var email = snap.data['email'];
                                  switch (snap.data['user_type']) {
                                    case 0:
                                      return StudentWelcome(
                                        rollNum:
                                            (email as String).split('@')[0],
                                      );
                                    case 9:
                                      return ProfessorWelcome(
                                        emailPrefix:
                                            (email as String).split('@')[0],
                                      );
                                    default:
                                      return const Placeholder();
                                  }
                                } else {
                                  return const Text(
                                    'Something unexpected has occured, '
                                    'please clear the app data and try again :(',
                                  );
                                }
                              }
                              return const CircularProgressIndicator();
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StudentWelcome extends StatefulWidget {
  final String rollNum;

  const StudentWelcome({
    super.key,
    required this.rollNum,
  });

  @override
  State<StudentWelcome> createState() => _StudentWelcomeState();
}

class _StudentWelcomeState extends State<StudentWelcome> {
  late Future<Map<String, dynamic>> studentFuture;

  @override
  void initState() {
    studentFuture = StudentApiController().getStudent(widget.rollNum);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: studentFuture,
      builder: (BuildContext context, AsyncSnapshot snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.data['status'] == 200) {
            return Column(
              children: [
                Text('Welcome, ${snap.data['students'][0]['name']}!'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return StudentDashboard(
                                rollNum: widget.rollNum,
                                name: snap.data['students'][0]['name'],
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Contiue'),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    IconButton.filled(
                      onPressed: () async {
                        UserApiController().logout();
                        Phoenix.rebirth(context);
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return const Text(
              'Something unexpected has occured, '
              'please clear the app data and try again :(',
            );
          }
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

class ProfessorWelcome extends StatefulWidget {
  final String emailPrefix;

  const ProfessorWelcome({
    super.key,
    required this.emailPrefix,
  });

  @override
  State<ProfessorWelcome> createState() => _ProfessorWelcomeState();
}

class _ProfessorWelcomeState extends State<ProfessorWelcome> {
  late Future<Map<String, dynamic>> professorFuture;

  @override
  void initState() {
    professorFuture = ProfessorApiController().getData(widget.emailPrefix);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: professorFuture,
      builder: (BuildContext context, AsyncSnapshot snap) {
        if (snap.hasData) {
          if (snap.data['status'] == 200) {
            return Column(
              children: [
                Text('Welcome, ${snap.data['professors'][0]['name']}!'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ProfessorDashboard(
                                emailPrefix: widget.emailPrefix,
                                name: snap.data['professors'][0]['name'],
                              );
                            },
                            settings: const RouteSettings(name: "/profDash"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Contiue'),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    IconButton.filled(
                      onPressed: () async {
                        UserApiController().logout();
                        Phoenix.rebirth(context);
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return const Text(
              'Something unexpected has occured, '
              'please clear the app data and try again :(',
            );
          }
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() {
    return LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  var email = '';
  // otpSent, buttonEnabled
  var states = [false, true];

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(value)) {
      setState(() {
        email = value.toLowerCase();
      });
    } else {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? otpValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    var otp_ = int.tryParse(value.toString());
    if (otp_ == null) {
      return 'Please enter a valid OTP';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (states[0])
              ? OtpTextField(
                  numberOfFields: 4,
                  enabledBorderColor: Theme.of(context).colorScheme.secondary,
                  borderColor: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                  focusedBorderColor: Theme.of(context).colorScheme.primary,
                  showFieldAsBox: true,
                  onCodeChanged: (value) => otpValidator(value),
                  onSubmit: (String otp) async {
                    scaffoldMessenger.hideCurrentSnackBar();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Checking OTP...')),
                    );
                    setState(() {
                      states[1] = false;
                    });
                    var response = await UserApiController()
                        .checkOtp(email, int.parse(otp));
                    setState(() {
                      states[1] = true;
                    });
                    if (response['status'] == 500) {
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content: Text('Internal server error D:')),
                      );
                    }
                    if (response['status'] == 200) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        Phoenix.rebirth(context);
                      });
                    }
                  }, // end onSubmit
                )
              : TextFormField(
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(width: 1, color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 1.5,
                          color: Theme.of(context).colorScheme.error),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 2, color: Theme.of(context).colorScheme.error),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: 'Email',
                    suffixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) => emailValidator(value),
                ),
          const SizedBox(
            height: 15,
          ),
          (!states[0])
              ? FilledButton(
                  onPressed: (states[1])
                      ? () async {
                          bool validationState =
                              _formKey.currentState!.validate();
                          if (validationState) {
                            scaffoldMessenger.hideCurrentSnackBar();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                  content: Text('Sending OTP to $email...')),
                            );
                            setState(() {
                              states[1] = false;
                            });
                            var response =
                                await UserApiController().sendOtp(email);
                            setState(() {
                              states[1] = true;
                            });
                            if (response['status'] != 500) {
                              scaffoldMessenger.hideCurrentSnackBar();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text(response['message'])),
                              );
                            } else {
                              scaffoldMessenger.hideCurrentSnackBar();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Internal server error D:')),
                              );
                            }
                            if (response['status'] == 200) {
                              _formKey.currentState!.reset();
                              setState(() {
                                states[0] = true;
                              });
                            }
                          }
                        }
                      : null,
                  child: (states[1])
                      ? const Text('Send OTP')
                      : SizedBox(
                          height: Theme.of(context).buttonTheme.height - 15,
                          width: Theme.of(context).buttonTheme.height - 15,
                          child: LoadingIndicator(
                            indicatorType: Indicator.lineScale,
                            colors: [Theme.of(context).colorScheme.primary],
                            strokeWidth: 4.0,
                            pathBackgroundColor: Colors.black45,
                          ),
                        ),
                )
              : const SizedBox(
                  height: 0,
                )
        ],
      ),
    );
  }
}
