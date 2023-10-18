import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:iiitr_connect/api/face_encodings_api.dart';

class AddFaceData extends StatefulWidget {
  const AddFaceData({
    super.key,
    required this.rollNum,
  });

  final String rollNum;

  @override
  State<AddFaceData> createState() => _AddFaceDataState();
}

class _AddFaceDataState extends State<AddFaceData> {
  Future<CameraDescription> get getCameraDesc async {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    return cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
  }

  final pageController = PageController(initialPage: 0);
  final List<String> photos = [];
  final List<bool> onSubmitPage = [false, false];

  @override
  void dispose() {
    pageController.jumpToPage(1);
    pageController.dispose();
    super.dispose();
  }

  void enableBackOnSubmitPage() {
    setState(() {
      onSubmitPage[1] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool willPop = !onSubmitPage[0];
        if (!willPop) {
          willPop = onSubmitPage[1];
        }
        return willPop;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Add face data'),
          automaticallyImplyLeading: !onSubmitPage[0],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: PageView(
              controller: pageController,
              onPageChanged: (value) {
                setState(() {
                  onSubmitPage[0] = value == 1;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: FutureBuilder(
                        future: getCameraDesc,
                        builder: (BuildContext context, AsyncSnapshot snap) {
                          if (snap.data == null) {
                            return const CircularProgressIndicator();
                          } else {
                            return TakePictureScreen(
                              camera: snap.data,
                              parentPageController: pageController,
                              photos: photos,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SubmitPhotosScreen(
                  parentPageController: pageController,
                  photos: photos,
                  rollNum: widget.rollNum,
                  onSubmit: enableBackOnSubmitPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
    required this.parentPageController,
    required this.photos,
  });

  final CameraDescription camera;
  final PageController parentPageController;
  final List<String> photos;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final imageNotifier = ValueNotifier<List<String>>([]);

  bool canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    canSubmit = widget.photos.length >= 3;
    imageNotifier.value.addAll(widget.photos);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(8)),
                child: CameraPreview(_controller),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    label: const Text('Capture'),
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      try {
                        await _initializeControllerFuture;
                        final image = await _controller.takePicture();
                        await FaceEncodingsApiController.bakeRotation(
                            image.path);
                        if (!mounted) return;

                        final List<String> images = [...imageNotifier.value];
                        images.add(image.path);
                        imageNotifier.value = images;
                        widget.photos.add(image.path);

                        if (images.length >= 3) {
                          setState(() {
                            canSubmit = true;
                          });
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    label: const Text('Submit'),
                    icon: const Icon(Icons.check),
                    onPressed: (canSubmit)
                        ? () {
                            widget.parentPageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic);
                          }
                        : null,
                  ),
                ],
              ),
              Text(
                'Please click at least 3 photos to continue',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(
                height: 100,
                width: 500,
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: imageNotifier,
                  builder: (BuildContext context, images, Widget? child) {
                    return ListView.separated(
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (BuildContext context, index) => InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierLabel: 'Preview',
                            builder: (BuildContext context) => Dialog(
                              clipBehavior: Clip.hardEdge,
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    Image.file(File(images[index])),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            final List<String> images = [
                                              ...imageNotifier.value
                                            ];
                                            images.removeAt(index);
                                            imageNotifier.value = images;
                                            widget.photos.removeAt(index);

                                            if (images.length < 3) {
                                              setState(() {
                                                canSubmit = false;
                                              });
                                            }

                                            Navigator.of(context).pop();
                                          },
                                          icon: const Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.file(File(images[index])),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class SubmitPhotosScreen extends StatefulWidget {
  const SubmitPhotosScreen({
    super.key,
    required this.parentPageController,
    required this.photos,
    required this.rollNum,
    required this.onSubmit,
  });

  final PageController parentPageController;
  final List<String> photos;
  final String rollNum;
  final Function onSubmit;

  @override
  State<SubmitPhotosScreen> createState() => _SubmitPhotosScreenState();
}

class _SubmitPhotosScreenState extends State<SubmitPhotosScreen> {
  late Future photosValidated;
  late List<Map<String, dynamic>> photoFutures;

  final List<bool> canExit = [false];

  @override
  void initState() {
    super.initState();
    photosValidated = sendAllPhotos();
    photosValidated.then((value) {
      setState(() {
        canExit[0] = true;
      });
      widget.onSubmit();
    });
  }

  Future sendAllPhotos() async {
    var allResp = List<Map<String, dynamic>>.empty(growable: true);
    await Future.forEach(widget.photos, (photo) async {
      var response = await FaceEncodingsApiController()
          .uploadFaceData(widget.rollNum, photo);
      allResp.add(response);
    });
    photoFutures = allResp;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                width: 3),
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            'Please wait while all the photos are uploaded to the server and validated. '
            'Your photos are not stored on the server. '
            'Blurry photos or photos not containing exactly one face will be rejected.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.70,
          width: MediaQuery.of(context).size.width,
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.of(context).size.width / 2,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemCount: widget.photos.length,
              itemBuilder: (BuildContext context, index) => InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierLabel: 'Preview',
                    builder: (BuildContext context) => Dialog(
                      clipBehavior: Clip.hardEdge,
                      child: IntrinsicHeight(
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.file(
                              File(widget.photos[index]),
                            )),
                      ),
                    ),
                  );
                },
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Image.file(File(widget.photos[index])),
                      FutureBuilder(
                        future: photosValidated,
                        builder: (BuildContext context, AsyncSnapshot snap) {
                          if (snap.connectionState == ConnectionState.done) {
                            if (photoFutures[index]['status'] == 400) {
                              return Container(
                                alignment: const Alignment(0, 0),
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    Text(
                                      ' PHOTO REJECTED',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (photoFutures[index]['status'] == 200) {
                              var painterKey = GlobalKey();
                              return Container(
                                key: painterKey,
                                width: double.infinity,
                                height: double.infinity,
                                child: CustomPaint(
                                  painter: RectanglePainter(
                                    selfKey: painterKey,
                                    photoWidth: photoFutures[index]
                                        ['dimensions']['width'],
                                    photoHeight: photoFutures[index]
                                        ['dimensions']['height'],
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    p1: {
                                      'x': photoFutures[index]['face'][0]['x'],
                                      'y': photoFutures[index]['face'][0]['y'],
                                    },
                                    p2: {
                                      'x': photoFutures[index]['face'][1]['x'],
                                      'y': photoFutures[index]['face'][1]['y'],
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                          return Container(
                            color: const Color.fromARGB(166, 0, 0, 0),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Finish'),
          onPressed: (canExit[0]) ? () {
            Navigator.of(context).pop();
          } : null,
        ),
      ],
    );
  }
}

class RectanglePainter extends CustomPainter {
  final GlobalKey selfKey;
  final int photoWidth;
  final int photoHeight;
  final Map<String, int> p1;
  final Map<String, int> p2;
  final Color color;

  const RectanglePainter({
    required this.selfKey,
    required this.photoWidth,
    required this.photoHeight,
    required this.p1,
    required this.p2,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    RenderBox renderBox =
        selfKey.currentContext?.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    double heightScale = size.height / photoHeight.toDouble();
    double widthScale = size.width / photoWidth.toDouble();
    var o1 = Offset(p1['x']!.toDouble() * heightScale, p1['y']!.toDouble() * widthScale);
    var o2 = Offset(p2['x']!.toDouble() * heightScale, p2['y']!.toDouble() * widthScale);
    final rect = Rect.fromPoints(o1, o2);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
