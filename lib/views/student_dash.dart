import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:iiitr_connect/api/user_api.dart';

class StudentDashboard extends StatefulWidget {
  final String rollNum;
  final String name;

  const StudentDashboard({
    Key? key,
    required this.rollNum,
    required this.name,
  }) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text(
          'IIITR Connect',
          style: TextStyle(
            fontFamily: 'Mooli',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(
                    height: 55,
                    width: 55,
                    child: Icon(Icons.person),
                  ),
                  Text(
                    'STUDENT',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    widget.rollNum,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Row(
                children: [
                  Icon(Icons.book),
                  SizedBox(
                    width: 10,
                  ),
                  Text('Courses'),
                ],
              ),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Row(
                children: [
                  Icon(Icons.forum),
                  SizedBox(
                    width: 10,
                  ),
                  Text('Grievances'),
                ],
              ),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(
                    width: 10,
                  ),
                  Text('Log out'),
                ],
              ),
              onTap: () async {
                UserApiController().logout();
                Phoenix.rebirth(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Text('Welcome, ${widget.name}!'),
          ],
        ),
      ),
    );
  }
}
