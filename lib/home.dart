import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:generatelivecaptions/generatecaptions.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _loading = true;
  File _image;
  final picker = ImagePicker();
  String resultText = "Fetching Response...";

  pickImage() async {
    var image = await picker.getImage(source: ImageSource.camera);

    if (image == null) return null;

    setState(() {
      _image = File(image.path);
      _loading = false;
    });
    var str = fetchResponse(_image);
    print(str);
  }

  pickGalleryImage() async {
    var image = await picker.getImage(source: ImageSource.gallery);

    if (image == null) return null;

    setState(() {
      _image = File(image.path);
      _loading = false;
    });
    var str = fetchResponse(_image);
    print(str);
    // var
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
          color: Colors.black,
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   stops: [0.004, 1],
          //   colors: [Color(0x11232526), Color(0xFF232526)],
          // ),
        ),
        child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 98),
                // Text(
                //   'Text Generator',
                //   style: TextStyle(
                //     color: Colors.black,
                //     fontWeight: FontWeight.bold,
                //     fontSize: 35,
                //   ),
                // ),
                // Text(
                //   'Image to text Generator',
                //   style: TextStyle(
                //       color: Colors.black,
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold),
                // ),
                // SizedBox(height: 80),
                Container(
                    // height: MediaQuery.of(context).size.height - 250,
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Center(
                          child: _loading
                              ? Container(
                                  // width: 500,
                                  // height: 8,
                                  child: Column(
                                  children: <Widget>[
                                    Text(
                                      'Text Generator',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 35,
                                      ),
                                    ),
                                    Text(
                                      'Image to text Generator',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 30,
                                    ),
                                    Container(
                                      width: 150,
                                      child: Image.asset(
                                        'assets/notepad.png',
                                      ),
                                    ),
                                    SizedBox(height: 50),
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          GenerateLiveCaptions()));
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  180,
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 17),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Live Camera',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: pickGalleryImage,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  180,
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 17),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Camera Roll',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: pickImage,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  180,
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 17),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Take a Photo',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ))
                              : Container(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          height: 200,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Container(
                                                child: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _loading = true;
                                                      resultText =
                                                          "Fetching Response...";
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Icons.arrow_back_ios,
                                                  ),
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    205,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.file(_image,
                                                      fit: BoxFit.fill),
                                                ),
                                              ),
                                            ],
                                          )),
                                      SizedBox(height: 20),
                                      Container(
                                        child: Text(
                                          '$resultText',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    ],
                                  )),
                        )
                      ],
                    )),
              ],
            )),
      ),
    );
  }
}
