import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class AddFaceData extends StatefulWidget {
  const AddFaceData({
    super.key,
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add face data'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                // height: MediaQuery.of(context).size.height - 150,
                // width: MediaQuery.of(context).size.width - 20,
                alignment: Alignment.center,
                child: FutureBuilder(
                  future: getCameraDesc,
                  builder: (BuildContext context, AsyncSnapshot snap) {
                    if (snap.data == null) {
                      return const CircularProgressIndicator();
                    } else {
                      return TakePictureScreen(camera: snap.data);
                    }
                  },
                ),
              ),
            ],
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
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.low,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return Column(
            children: [
              CameraPreview(_controller),
              FloatingActionButton(
                // Provide an onPressed callback.
                onPressed: () async {
                  // Take the Picture in a try / catch block. If anything goes wrong,
                  // catch the error.
                  try {
                    // Ensure that the camera is initialized.
                    await _initializeControllerFuture;

                    // Attempt to take a picture and then get the location
                    // where the image file is saved.
                    final image = await _controller.takePicture();
                  } catch (e) {
                    // If an error occurs, log the error to the console.
                    print(e);
                  }
                },
                child: const Icon(Icons.camera_alt),
              )
            ],
          );
        } else {
          // Otherwise, display a loading indicator.
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
