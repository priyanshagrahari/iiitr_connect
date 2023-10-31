import 'package:flutter/material.dart';
import 'package:iiitr_connect/api/face_encodings_api.dart';
import 'package:iiitr_connect/views/add_face_data.dart';
import 'package:iiitr_connect/views/courses_page.dart';
import 'package:loading_indicator/loading_indicator.dart';

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
            CoursesPage(
              studRollNum: widget.rollNum,
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
            children: [
              AddFaceDataCard(rollNum: widget.rollNum),
            ],
          ),
        ),
      ],
    );
  }
}

class AddFaceDataCard extends StatefulWidget {
  const AddFaceDataCard({
    super.key,
    required this.rollNum,
  });

  final String rollNum;

  @override
  State<AddFaceDataCard> createState() => _AddFaceDataCardState();
}

class _AddFaceDataCardState extends State<AddFaceDataCard> {
  late Future numEncodingsFuture;
  int numEncodings = 0;

  @override
  void initState() {
    super.initState();
    initFuture();
  }

  void initFuture() {
    numEncodingsFuture =
        FaceEncodingsApiController().getNumEncodings(widget.rollNum);
    numEncodingsFuture.then(
      (value) {
        if (value['status'] == 200 && value['count'] < 3) {
          showBlockingDialog();
        }
        if (!mounted) return;
        setState(() {
          numEncodings = (value['status'] == 200) ? value['count'] : 0;
        });
      },
    );
  }

  void showBlockingDialog() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Text(
                        'Please add face recognition data before continuing. '
                        'There must be at least 3 valid encodings.'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                              ..pop()
                              ..push(
                                MaterialPageRoute(
                                  builder: (context) => AddFaceData(
                                    rollNum: widget.rollNum,
                                    willPop: () {
                                      initFuture();
                                    },
                                  ),
                                ),
                              );
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Add data'),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Helps in better face recognition for marking attendance.'),
                  FutureBuilder(
                    future: numEncodingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Text(
                            "Number of valid encodings: $numEncodings",
                            textAlign: TextAlign.start,);
                      } else {
                        return SizedBox(
                          height: Theme.of(context).buttonTheme.height - 15,
                          width: Theme.of(context).buttonTheme.height - 15,
                          child: LoadingIndicator(
                            indicatorType: Indicator.lineScale,
                            colors: [Theme.of(context).colorScheme.primary],
                            strokeWidth: 4.0,
                            pathBackgroundColor: Colors.black45,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
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
                          rollNum: widget.rollNum,
                          willPop: () {
                            initFuture();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
