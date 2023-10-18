import 'package:flutter/material.dart';
import 'package:iiitr_connect/views/add_face_data.dart';

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
  int currentPageIndex = 1;
  final controller = PageController(initialPage: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        onDestinationSelected: (int index) {
          controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 555),
            curve: Curves.easeInOutCubic,
          );
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: Theme.of(context).colorScheme.inversePrimary,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.school),
            icon: Icon(Icons.school_outlined),
            label: 'Courses',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.dashboard),
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.forum),
            icon: Icon(Icons.forum_outlined),
            label: 'Forum',
          ),
        ],
      ),
      body: SafeArea(
        child: PageView(
          onPageChanged: (value) {
            setState(() {
              currentPageIndex = value;
            });
          },
          controller: controller,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: const Text('Courses Page'),
            ),
            Dashboard(widget: widget),
            Container(
              alignment: Alignment.center,
              child: const Text('Forum Page'),
            ),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.widget,
  });

  final StudentDashboard widget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text(
            'Welcome, ${widget.name}!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
            ),
          ),
        ),
        AddFaceDataCard(rollNum: widget.rollNum),
      ],
    );
  }
}

class AddFaceDataCard extends StatelessWidget {
  const AddFaceDataCard({
    super.key,
    required this.rollNum,
  });

  final String rollNum;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Add face recognition data',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                ),
              ),
              subtitle: const Text(
                  'Helps in better face recognition for marking attendance.'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Add data'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFaceData(
                          rollNum: rollNum,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
