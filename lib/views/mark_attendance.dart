import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iiitr_connect/api/face_encodings_api.dart';
import 'package:iiitr_connect/api/lecture_api.dart';
import 'package:iiitr_connect/api/student_api.dart';
import 'package:image_picker/image_picker.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({
    super.key,
    required this.lecture,
    required this.dateString,
    required this.onSaved,
  });

  final LectureModel lecture;
  final String dateString;
  final Function onSaved;

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class AttendanceTileData {
  const AttendanceTileData({
    required this.registrationId,
    required this.studentRoll,
    required this.studentName,
  });

  final String registrationId;
  final String studentRoll;
  final String studentName;
}

// ignore: must_be_immutable
class AttendanceTile extends StatefulWidget {
  AttendanceTile({
    super.key,
    required this.data,
    required this.onTap,
    required this.isOnPresentList,
  });

  final AttendanceTileData data;
  final Function(String regId, bool isOnPresentList) onTap;
  bool isOnPresentList = false;

  @override
  State<AttendanceTile> createState() => _AttendanceTileState();
}

class _AttendanceTileState extends State<AttendanceTile>
    with TickerProviderStateMixin {
  late final AnimationController _moveController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _moveAnimation = CurvedAnimation(
    parent: _moveController,
    curve: Curves.fastOutSlowIn,
  );

  bool closing = false;

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  void onTap() {
    setState(() {
      closing = true;
    });
    _moveController.forward().then((value) {
      widget.onTap(widget.data.registrationId, widget.isOnPresentList);
    });
  }

  @override
  Widget build(context) {
    return SizeTransition(
      sizeFactor: ReverseAnimation(_moveAnimation),
      axis: Axis.vertical,
      axisAlignment: 1,
      child: AnimatedContainer(
        curve: Curves.linear,
        duration: _moveController.duration!,
        color: (closing)
            ? (widget.isOnPresentList)
                ? Colors.red
                : Colors.green
            : Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
              ),
              Expanded(
                child: ListTile(
                  isThreeLine: true,
                  title: Text(widget.data.studentRoll),
                  titleAlignment: ListTileTitleAlignment.center,
                  subtitle: Text(widget.data.studentName),
                  trailing: IconButton(
                    onPressed: () {
                      onTap();
                    },
                    icon: widget.isOnPresentList
                        ? const Icon(Icons.person_remove)
                        : const Icon(Icons.person_add),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkAttendanceState extends State<MarkAttendance> {
  late Future<bool> attendanceInfoFuture;
  List<AttendanceTileData> allStudentsData = [];
  List<String> initPresentRollNums = [];
  double attendancePercent = 0;
  bool saved = false;
  bool changed = false;

  var allKeysMap = <String, GlobalKey<State<AttendanceTile>>>{};
  final presentNotifier = ValueNotifier<List<AttendanceTileData>>([]);
  final absentNotifier = ValueNotifier<List<AttendanceTileData>>([]);
  final tabControllerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    setFuture();
  }

  @override
  void dispose() {
    allKeysMap.clear();
    super.dispose();
  }

  void setFuture() {
    attendanceInfoFuture = sendRequests();
    attendanceInfoFuture.then((value) {
      updateAttendancePercent();
    });
  }

  Future<bool> sendRequests() async {
    setState(() {
      allKeysMap.clear();
    });
    var response =
        await StudentApiController().getByCourse(widget.lecture.course_id);
    if (!mounted) return false;
    if (response['status'] == 200) {
      List<AttendanceTileData> localAll = [];
      for (var map in response['registrations']) {
        var tileData = AttendanceTileData(
          registrationId: map['registration_id'],
          studentRoll: map['student']['roll_num'],
          studentName: map['student']['name'],
        );
        localAll.add(tileData);
      }
      setState(() {
        allStudentsData = localAll;
        initPresentRollNums.clear();
      });
    } else {
      setState(() {
        allStudentsData = [];
        initPresentRollNums.clear();
        presentNotifier.value = [];
        absentNotifier.value = [];
      });
      return false;
    }
    response = await LectureApiController()
        .getLectureAttendance(widget.lecture.lecture_id);
    if (!mounted) return false;
    if (response['status'] == 200) {
      // SOME STUDENTS PRESENT
      List<String> presentRollNums = (response['students'] as List<dynamic>)
          .map((e) => e['roll_num'] as String)
          .toList();
      setState(() {
        initPresentRollNums = presentRollNums;
        presentNotifier.value = [];
        presentNotifier.value = allStudentsData
            .where((element) => (presentRollNums.contains(element.studentRoll)))
            .toList();
        absentNotifier.value = [];
        absentNotifier.value = allStudentsData
            .where(
                (element) => (!presentRollNums.contains(element.studentRoll)))
            .toList();
      });
      return true;
    } else if (response['status'] == 404) {
      // NO STUDENTS PRESENT
      setState(() {
        initPresentRollNums.clear();
        presentNotifier.value = [];
        absentNotifier.value = [];
        absentNotifier.value.addAll(allStudentsData);
      });
      return true;
    } else {
      // SOME ERROR IDK
      setState(() {
        allStudentsData = [];
        initPresentRollNums.clear();
        presentNotifier.value = [];
        absentNotifier.value = [];
      });
    }
    return false;
  }

  void onTileTap(String regId, bool isOnPresentList) {
    var presentVal = presentNotifier.value;
    var absentVal = absentNotifier.value;
    if (isOnPresentList) {
      presentVal.firstWhereOrNull((element) {
        if (element.registrationId == regId) {
          absentVal.add(element);
          presentVal.remove(element);
          return true;
        }
        return false;
      });
    } else {
      absentVal.firstWhereOrNull((element) {
        if (element.registrationId == regId) {
          presentVal.add(element);
          absentVal.remove(element);
          return true;
        }
        return false;
      });
    }
    presentNotifier.value = presentVal;
    absentNotifier.value = absentVal;
    checkModified();
    updateAttendancePercent();
  }

  void updateAttendancePercent() {
    if (allStudentsData.isEmpty) return;
    setState(() {
      attendancePercent =
          100 * presentNotifier.value.length / allStudentsData.length;
    });
  }

  void checkModified() {
    if (presentNotifier.value.length != initPresentRollNums.length) {
      setState(() {
        changed = true;
      });
      return;
    }
    for (var presentData in presentNotifier.value) {
      if (!initPresentRollNums.contains(presentData.studentRoll)) {
        setState(() {
          changed = true;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (changed) {
          await showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        title: Text('There are unsaved changes!'),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Keep Editing'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                ..pop()
                                ..pop();
                            },
                            child: const Text('Discard Changes'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            children: [
              Text(
                'ATTENDANCE FOR',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(widget.dateString),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.primary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restore),
              label: "Restore",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.save),
              label: "Save",
            ),
          ],
          onTap: (value) async {
            if (value == 0) {
              setFuture();
              setState(() {
                changed = false;
              });
            } else if (changed || !widget.lecture.atten_marked) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Saving...')));
              });
              var response = await LectureApiController().markLectureAttendance(
                widget.lecture.lecture_id,
                presentNotifier.value.map((e) => e.registrationId).toList(),
              );
              if (!mounted) return;
              if (response['status'] == 200) {
                setState(() {
                  saved = true;
                  changed = false;
                });
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response['message'])));
                });
                widget.onSaved();
              }
            } else {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No changes to save!')));
              });
            }
          },
        ),
        body: FutureBuilder(
          future: attendanceInfoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!) {
              return Column(
                children: [
                  Text(
                    '${attendancePercent.ceil()}%', // ATTENDANCE PERCENTAGE HERE
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  RichText(
                    text: TextSpan(
                      text: 'STATUS: ',
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                            text: (widget.lecture.atten_marked || saved)
                                ? 'MARKED'
                                : 'NOT MARKED',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  StudentsFromCamera(
                    lectureId: widget.lecture.lecture_id,
                    allStudentsData: allStudentsData,
                    sendMatches: (rollList) async {
                      var tabController = DefaultTabController.of(
                          tabControllerKey.currentContext!);
                      tabController.animateTo(0,
                          duration: const Duration(milliseconds: 300));
                      await Future.delayed(const Duration(milliseconds: 400));
                      for (var element in rollList) {
                        if (allKeysMap[element]!.currentState != null) {
                          if (!allKeysMap[element]!
                              .currentState!
                              .widget
                              .isOnPresentList) {
                            (allKeysMap[element]!.currentState
                                    as _AttendanceTileState)
                                .onTap();
                          }
                        } else {
                          onTileTap(
                            allStudentsData
                                .firstWhere((e) => e.studentRoll == element)
                                .registrationId,
                            false,
                          );
                        }
                      }
                    },
                  ),
                  DefaultTabController(
                    length: 2,
                    child: Expanded(
                      child: Column(
                        children: [
                          TabBar(
                            tabs: [
                              Tab(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(),
                                      const Text('ABSENT'),
                                      (absentNotifier.value.isNotEmpty)
                                          ? Text(
                                              '${absentNotifier.value.length}')
                                          : const SizedBox()
                                    ],
                                  ),
                                ),
                              ),
                              Tab(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(),
                                      const Text('PRESENT'),
                                      (presentNotifier.value.isNotEmpty)
                                          ? Text(
                                              '${presentNotifier.value.length}')
                                          : const SizedBox()
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              key: tabControllerKey,
                              children: [
                                ValueListenableBuilder(
                                  valueListenable: absentNotifier,
                                  builder: (context, value, child) {
                                    if (value.isNotEmpty) {
                                      return ListView(
                                        children: value.map((e) {
                                          if (allKeysMap[e.studentRoll] ==
                                              null) {
                                            allKeysMap[e.studentRoll] =
                                                GlobalKey();
                                          }
                                          return AttendanceTile(
                                            key: allKeysMap[e.studentRoll],
                                            data: e,
                                            onTap: onTileTap,
                                            isOnPresentList: false,
                                          );
                                        }).toList(),
                                      );
                                    } else {
                                      return const SizedBox.expand(
                                        child: Center(
                                          child: Text('No absent students'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                ValueListenableBuilder(
                                  valueListenable: presentNotifier,
                                  builder: (context, value, child) {
                                    if (value.isNotEmpty) {
                                      return ListView(
                                        children: value.mapIndexed((idx, e) {
                                          if (allKeysMap[e.studentRoll] ==
                                              null) {
                                            allKeysMap[e.studentRoll] =
                                                GlobalKey();
                                          }
                                          return AttendanceTile(
                                            key: allKeysMap[e.studentRoll],
                                            data: e,
                                            onTap: onTileTap,
                                            isOnPresentList: true,
                                          );
                                        }).toList(),
                                      );
                                    } else {
                                      return const SizedBox.expand(
                                        child: Center(
                                          child: Text('No present students'),
                                        ),
                                      );
                                    }
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class StudentsFromCamera extends StatefulWidget {
  const StudentsFromCamera({
    super.key,
    required this.lectureId,
    required this.sendMatches,
    required this.allStudentsData,
  });

  final String lectureId;
  final List<AttendanceTileData> allStudentsData;
  final Function(List<String>) sendMatches;

  @override
  State<StudentsFromCamera> createState() => _StudentsFromCameraState();
}

class _StudentsFromCameraState extends State<StudentsFromCamera> {
  final imageNotifier = ValueNotifier<List<String>>([]);
  final cardKeys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Please make sure that all faces are oriented vertically',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: imageNotifier,
                    builder: (context, images, child) {
                      if (images.isNotEmpty) {
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          children: images.mapIndexed((idx, e) {
                            if (cardKeys[e] == null) {
                              cardKeys[e] = GlobalKey();
                            }
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: (idx != images.length - 1) ? 10 : 0),
                              child: UploadingClassPhotoCard(
                                cardKeys[e],
                                lectureId: widget.lectureId,
                                imgPath: e,
                                allStudentsData: widget.allStudentsData,
                                sendMatches: (rollList) {
                                  widget.sendMatches(rollList);
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }
                      return const Center(child: Text('No images added yet'));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                AddPhotoCard(imageNotifier: imageNotifier),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class UploadingClassPhotoCard extends StatefulWidget {
  const UploadingClassPhotoCard(
    key, {
    required this.lectureId,
    required this.imgPath,
    required this.sendMatches,
    required this.allStudentsData,
  }) : super(key: key);

  final String lectureId;
  final String imgPath;
  final List<AttendanceTileData> allStudentsData;
  final Function(List<String>) sendMatches;

  @override
  State<UploadingClassPhotoCard> createState() =>
      _UploadingClassPhotoCardState();
}

class _UploadingClassPhotoCardState extends State<UploadingClassPhotoCard>
    with AutomaticKeepAliveClientMixin {
  late Future validationFuture;
  List<Map<int, dynamic>> foundFaces = [];
  List<Map<int, Offset>> notFoundFaces = [];
  late Offset photoDimensions;

  @override
  void initState() {
    super.initState();
    print('will try sending request for ${widget.imgPath}');
    validationFuture = FaceEncodingsApiController()
        .uploadClassPhoto(widget.lectureId, widget.imgPath);
    validationFuture.then((value) {
      if (!mounted) return;
      if (value['status'] == 200 || value['status'] == 404) {
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(value['message'])));
        });
        photoDimensions = Offset(
          (value['dimensions']['width'] as int).toDouble(),
          (value['dimensions']['height'] as int).toDouble(),
        );
        if (value['found_faces'].isNotEmpty) {
          for (var match in value['found_faces']) {
            String key = "";
            int value = 0;
            (match['matches']).forEach((k, v) {
              if (v > value) {
                value = v;
                key = k;
              }
            });
            foundFaces.add({
              -1: key,
              0: Offset(match['face'][0]['x'].toDouble(),
                  match['face'][0]['y'].toDouble()),
              1: Offset(match['face'][1]['x'].toDouble(),
                  match['face'][1]['y'].toDouble()),
            });
          }
        }
        if (value['not_found_faces'].isNotEmpty) {
          for (var unmatch in value['not_found_faces']) {
            notFoundFaces.add({
              0: Offset(unmatch['face'][0]['x'].toDouble(),
                  unmatch['face'][0]['y'].toDouble()),
              1: Offset(unmatch['face'][1]['x'].toDouble(),
                  unmatch['face'][1]['y'].toDouble()),
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.file(File(widget.imgPath)),
          FutureBuilder(
            future: validationFuture,
            builder: (BuildContext context, AsyncSnapshot snap) {
              if (snap.connectionState == ConnectionState.done) {
                if (snap.data != null) {
                  if (snap.data['status'] == 200) {
                    return Center(
                      child: IconButton.filled(
                        iconSize: 30,
                        style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.green),
                          foregroundColor:
                              MaterialStatePropertyAll(Colors.white),
                        ),
                        icon: const Icon(Icons.remove_red_eye),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierLabel: 'Preview',
                            builder: (BuildContext context) =>
                                ViewClassPhotoResultDialog(
                              imgPath: widget.imgPath,
                              sendMatches: widget.sendMatches,
                              photoDimensions: photoDimensions,
                              foundFaces: foundFaces,
                              notFoundFaces: notFoundFaces,
                              allStudentsData: widget.allStudentsData,
                            ),
                          );
                        },
                      ),
                    );
                  } else if (snap.data['status'] == 404) {
                    return const Center(
                      child: Icon(
                        Icons.error,
                        size: 50,
                        color: Colors.yellow,
                      ),
                    );
                  }
                } else {
                  return const Center(
                    child: Icon(
                      Icons.error,
                      size: 50,
                      color: Colors.red,
                    ),
                  );
                }
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ViewClassPhotoResultDialog extends StatefulWidget {
  const ViewClassPhotoResultDialog({
    super.key,
    required this.imgPath,
    required this.sendMatches,
    required this.foundFaces,
    required this.notFoundFaces,
    required this.allStudentsData,
    required this.photoDimensions,
  });

  final String imgPath;
  final Function(List<String>) sendMatches;
  final List<Map<int, dynamic>> foundFaces;
  final List<Map<int, Offset>> notFoundFaces;
  final Offset photoDimensions;
  final List<AttendanceTileData> allStudentsData;

  @override
  State<ViewClassPhotoResultDialog> createState() =>
      _ViewClassPhotoResultDialogState();
}

class _ViewClassPhotoResultDialogState
    extends State<ViewClassPhotoResultDialog> {
  List<int> selectedIndices = [];
  final boxesPainterKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matches found!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '${widget.foundFaces.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: <Widget>[
                    Image.file(
                      File(widget.imgPath),
                    ),
                    SizedBox.expand(
                      child: CustomPaint(
                        painter: AllRectanglesPainter(
                          photoDimensions: widget.photoDimensions,
                          foundFaces: widget.foundFaces
                              .map(
                                  (e) => {0: e[0] as Offset, 1: e[1] as Offset})
                              .toList(),
                          notFoundFaces: widget.notFoundFaces,
                          selectedIndices: selectedIndices,
                          selectedColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: widget.foundFaces.length,
                itemBuilder: (context, index) {
                  String studentRoll = widget.foundFaces[index][-1];
                  String studentName = widget.allStudentsData
                      .firstWhere((element) =>
                          (element.studentRoll == widget.foundFaces[index][-1]))
                      .studentName;
                  return ListTile(
                    leading: const Icon(Icons.person),
                    selected: selectedIndices.contains(index),
                    selectedTileColor: Theme.of(context).colorScheme.primary,
                    selectedColor: Theme.of(context).colorScheme.onPrimary,
                    visualDensity: const VisualDensity(
                        vertical: VisualDensity.minimumDensity),
                    title: Text("$studentRoll - $studentName"),
                    onTap: () {
                      if (selectedIndices.contains(index)) {
                        setState(() {
                          selectedIndices.remove(index);
                        });
                        return;
                      }
                      setState(() {
                        selectedIndices.add(index);
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mark as present:',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          widget.sendMatches(widget.foundFaces
                              .map((e) => e[-1] as String)
                              .toList());
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.done_all),
                        label: const Text('All'),
                      ),
                      Text(
                        'OR',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      FilledButton.icon(
                        onPressed: (selectedIndices.isEmpty)
                            ? null
                            : () {
                                widget.sendMatches(widget.foundFaces
                                    .whereIndexed((idx, e) =>
                                        selectedIndices.contains(idx))
                                    .map((e) => e[-1] as String)
                                    .toList());
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.check),
                        label: const Text('Selected'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AllRectanglesPainter extends CustomPainter {
  final Offset photoDimensions;
  final List<Map<int, Offset>> foundFaces;
  final List<Map<int, Offset>> notFoundFaces;
  final List<int> selectedIndices;
  final Color selectedColor;
  double? strokeWidth;

  AllRectanglesPainter({
    required this.photoDimensions,
    required this.foundFaces,
    required this.notFoundFaces,
    required this.selectedIndices,
    required this.selectedColor,
    this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double heightScale = size.height / photoDimensions.dy;
    double widthScale = size.width / photoDimensions.dx;

    final presentPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = strokeWidth ?? 2
      ..style = PaintingStyle.stroke;
    final selectedPaint = Paint()
      ..color = selectedColor
      ..strokeWidth = strokeWidth ?? 4
      ..style = PaintingStyle.stroke;
    for (int idx = 0; idx < foundFaces.length; idx++) {
      var face = foundFaces[idx];
      canvas.drawRect(
        Rect.fromPoints(
            Offset(face[0]!.dx * widthScale, face[0]!.dy * heightScale),
            Offset(face[1]!.dx * widthScale, face[1]!.dy * heightScale)),
        (selectedIndices.contains(idx)) ? selectedPaint : presentPaint,
      );
    }
    final absentPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = strokeWidth ?? 2
      ..style = PaintingStyle.stroke;
    for (var face in notFoundFaces) {
      canvas.drawRect(
        Rect.fromPoints(
            Offset(face[0]!.dx * widthScale, face[0]!.dy * heightScale),
            Offset(face[1]!.dx * widthScale, face[1]!.dy * heightScale)),
        absentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class AddPhotoCard extends StatelessWidget {
  const AddPhotoCard({
    super.key,
    required this.imageNotifier,
  });

  final ValueNotifier<List<String>> imageNotifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 30,
          tooltip: "Add using Camera",
          icon: const Icon(Icons.add_a_photo),
          onPressed: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? photo = await picker.pickImage(
                source: ImageSource.camera, requestFullMetadata: false);
            if (photo != null) {
              await FaceEncodingsApiController.bakeRotation(photo.path);
              final pathList = [photo.path, ...imageNotifier.value];
              imageNotifier.value = pathList;
            }
          },
        ),
        IconButton(
          iconSize: 30,
          tooltip: "Add from Gallery",
          icon: const Icon(Icons.photo_library),
          onPressed: () async {
            final ImagePicker picker = ImagePicker();
            final List<XFile?> photos =
                await picker.pickMultiImage(requestFullMetadata: false);
            if (photos.isNotEmpty) {
              var pathList = <String>[];
              for (var e in photos) {
                if (!imageNotifier.value.contains(e!.path)) {
                  pathList.insert(0, e.path);
                }
              }
              pathList.addAll(imageNotifier.value);
              imageNotifier.value = pathList;
            }
          },
        ),
      ],
    );
  }
}
