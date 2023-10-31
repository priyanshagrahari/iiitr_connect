import 'package:flutter/material.dart';
import 'package:iiitr_connect/views/courses_page.dart';

class ProfessorDashboard extends StatefulWidget {
  final String emailPrefix;
  final String name;

  const ProfessorDashboard({
    Key? key,
    required this.emailPrefix,
    required this.name,
  }) : super(key: key);

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
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
            CoursesPage(profPrefix: widget.emailPrefix),
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

  final ProfessorDashboard widget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: const Icon(
              Icons.account_circle,
              size: 70,
            ),
            title: Text(
              'Welcome, ${widget.name}!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
              ),
            ),
            subtitle: const Text('Have a nice day!'),
          ),
        ),
        Expanded(
          child: ListView(
            children: const [],
          ),
        ),
      ],
    );
  }
}
