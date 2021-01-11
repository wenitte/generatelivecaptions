import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;

class GenerateLiveCaptions extends StatefulWidget {
  @override
  _GenerateLiveCaptionsState createState() => _GenerateLiveCaptionsState();
}

class _GenerateLiveCaptionsState extends State<GenerateLiveCaptions> {
  String resultText = "Fetching Response...";
  List<CameraDescription> cameras;
  CameraController controller;
  bool takePhoto = false;

  @override
  void initState() {
    super.initState();
    takePhoto = true;
    detectCameras().then((_) {
      initializeController();
    });
  }

  Future<void> detectCameras() async {
    cameras = await availableCameras();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void initializeController() {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      if (takePhoto) {
        const interval = const Duration(seconds: 5);
        new Timer.periodic(interval, (Timer t) => capturePictures());
      }
    });
  }

  capturePictures() async {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/{$timestamp}.png';

    if (takePhoto) {
      controller.takePicture(filePath).then((_) {
        if (takePhoto) {
          File imgFile = File(filePath);
          fetchResponse(imgFile);
        } else {
          return;
        }
      });
    }
  }

  Future<Map<String, dynamic>> fetchResponse(File image) async {
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');

    final imageUploadRequest =
        http.MultipartRequest('POST', Uri.parse('ADD API HERE'));

    final file = await http.MultipartFile.fromPath('image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.fields['ext'] = mimeTypeData[1];
    imageUploadRequest.files.add(file);

    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> responseData = json.decode(response.body);
      parseResponse(responseData);
      return responseData;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void parseResponse(var response) {
    String r = "";
    var predictions = response['predictions'];
    for (var prediction in predictions) {
      var caption = prediction['caption'];
      var probability = prediction['probability'];
      r = r + '$caption\n\n';
    }
    setState(() {
      resultText = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.004, 1],
              colors: [
                Color(0x11232526),
                Color(0xFF232526),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 20),
                child: IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      takePhoto = false;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              (controller.value.isInitialized)
                  ? Center(child: buildCameraPreview())
                  : Container()
            ],
          )),
    );
  }

  Widget buildCameraPreview() {
    var size = MediaQuery.of(context).size.width / 1.2;
    return Column(
      children: <Widget>[
        Container(
            child: Column(
          children: <Widget>[
            SizedBox(
              height: 30,
            ),
            Container(
              width: size,
              height: size,
              child: CameraPreview(controller),
            ),
            SizedBox(height: 30),
            Text(
              'Prediction is: \n',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.w900,
                fontSize: 30,
              ),
            ),
            Text(
              resultText,
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ))
      ],
    );
  }
}
