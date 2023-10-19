import 'package:flutter/material.dart';
import 'package:iiitr_connect/api/lecture_api.dart';
import 'package:iiitr_connect/views/add_lecture_form.dart';
import 'package:iiitr_connect/views/course_view.dart';

class AllLectures extends StatefulWidget {
  const AllLectures({
    super.key,
    required this.courseId,
    required this.onDeleteOrUpdate,
  });

  final String courseId;
  final Function onDeleteOrUpdate;

  @override
  State<AllLectures> createState() => _AllLecturesState();
}

class _AllLecturesState extends State<AllLectures> {
  late Future allLecturesFuture;
  late List<LectureModel> allLectureModels = [];

  @override
  void initState() {
    initFuture();
    super.initState();
  }

  void initFuture() {
    allLecturesFuture = LectureApiController().getNLectures(widget.courseId, 0);
    allLecturesFuture.then((value) {
      if (mounted && value['status'] == 200) {
        setState(() {
          allLectureModels = (value['lectures'] as List<dynamic>)
              .map((e) => LectureModel.fromMap(map: e))
              .toList();
        });
      } else {
        setState(() {
          allLectureModels = [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Lectures'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Add Lecture'),
        icon: const Icon(Icons.post_add_outlined),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AddLectureForm(
                  courseId: widget.courseId,
                  reloadLectures: () {
                    widget.onDeleteOrUpdate();
                    initFuture();
                  },
                );
              },
            ),
          );
        },
      ),
      body: FutureBuilder(
        future: allLecturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data['status'] == 200 && allLectureModels.isNotEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  initFuture();
                },
                child: ListView.builder(
                  itemCount: allLectureModels.length,
                  itemBuilder: (context, index) {
                    return LectureCard(
                      lectureId: allLectureModels[index].lecture_id,
                      onUpdate: () => widget.onDeleteOrUpdate(),
                      onDelete: () {
                        widget.onDeleteOrUpdate();
                        initFuture();
                      },
                    );
                  },
                ),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () async {
                  initFuture();
                },
                child: ListView(
                  children: const [
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('No lectures found'),
                      ),
                    ),
                  ],
                ),
              );
            }
          }
          return const SizedBox(
            height: 50,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
