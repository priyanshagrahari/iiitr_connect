import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:iiitr_connect/api/user_api.dart';
import 'package:loading_indicator/loading_indicator.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).primaryColor,
      body: AnimateGradient(
        primaryColors: [
          Theme.of(context).colorScheme.primary,
          Colors.blueGrey,
        ],
        secondaryColors: [
          Colors.blue,
          Theme.of(context).colorScheme.primary,
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 15,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          'images/logoSquareWhite.png',
                          width: 180,
                          height: 180,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          'IIITR Connect',
                          style: TextStyle(
                            fontSize: 35,
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
                            future: UserApiController().verifyToken(),
                            builder: (BuildContext context, AsyncSnapshot snap) {
                              if (snap.data == null) {
                                return const CircularProgressIndicator();
                              } else {
                                // scaffoldMessenger.showSnackBar(
                                //   SnackBar(content: Text(snap.data['message'])),
                                // );
                                if (snap.data['status'] == 404 ||
                                    snap.data['status'] == 401) {
                                  return const LoginForm();
                                } else if (snap.data['status'] == 200) {
                                  var email = snap.data['email'];
                                  return Column(
                                    children: [
                                      Text('Welcome back, $email'),
                                      const LogoutButton(),
                                    ],
                                  );
                                } else {
                                  return const Text(
                                      'Something unexpected has occured, please clear the app data and reopen the app');
                                }
                              }
                            })
                      ],
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

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        UserApiController().logout();
        Phoenix.rebirth(context);
      },
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
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
  var otp = -1;
  // otpSent, buttonEnabled, loggedIn
  var states = [false, true, false];

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (value.toLowerCase().endsWith('@iiitr.ac.in')) {
      setState(() {
        email = value.toLowerCase();
      });
    } else {
      String lower = value.toLowerCase();
      setState(() {
        email = '$lower@iiitr.ac.in';
      });
    }
    return null;
  }

  String? otpValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    var otp_ = int.tryParse(value.toString());
    if (otp_ != null) {
      setState(() {
        otp = otp_;
      });
      return null;
    } else {
      return 'Please enter a valid OTP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    return (states[2])
        ? Column(
            children: [
              Text('Welcome, $email'),
              const LogoutButton(),
            ],
          )
        : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextFormField(
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
                            width: 2,
                            color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: (!states[0] ? 'Email' : 'OTP'),
                      suffix: (!states[0] ? const Text('@iiitr.ac.in') : null),
                      suffixIcon:
                          Icon((!states[0] ? Icons.email : Icons.numbers))),
                  validator: (value) =>
                      !states[0] ? emailValidator(value) : otpValidator(value),
                  initialValue: '',
                ),
                const SizedBox(
                  height: 15,
                ),
                FilledButton(
                  onPressed: (states[1])
                      ? () async {
                          bool validationState =
                              _formKey.currentState!.validate();
                          if (validationState && !states[0]) {
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
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text(response['message'])),
                              );
                            } else {
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
                            } else if (response['status'] == 404) {
                              //
                            }
                          } else if (validationState && states[0]) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Checking OTP...')),
                            );
                            setState(() {
                              states[1] = false;
                            });
                            var response =
                                await UserApiController().checkOtp(email, otp);
                            setState(() {
                              states[1] = true;
                            });
                            if (response['status'] != 500) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text(response['message'])),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Internal server error D:')),
                              );
                            }
                            if (response['status'] == 200) {
                              setState(() {
                                states[2] = true;
                              });
                            }
                          }
                        }
                      : null,
                  child: (states[1])
                      ? Text((!states[0]) ? 'Send OTP' : 'Login')
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
                ),
              ],
            ),
          );
  }
}
