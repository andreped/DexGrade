import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'tflite_service.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  List<Map<String, dynamic>>? _results;
  final TFLiteHelper _tfliteHelper = TFLiteHelper();
  double? _imageWidth;
  double? _imageHeight;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _tfliteHelper.loadModel();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  @override
  void dispose() {
    _tfliteHelper.disposeModel();
    super.dispose();
  }

  Future<void> _pickImage({required ImageSource source}) async {
    final pickedFile = await ImagePicker().getImage(source: source);
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      final decodedImage = img.decodeImage(image.readAsBytesSync());
      setState(() {
        _image = image;
        _imageWidth = decodedImage?.width.toDouble();
        _imageHeight = decodedImage?.height.toDouble();
      });
      _classifyImage(image);
    }
  }

  Future<void> _classifyImage(File image) async {
    var results = await _tfliteHelper.classifyImage(image);
    setState(() {
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snap Pokémon Card'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _results == null
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildRecognitionList(),
                    ),
              SizedBox(height: 20),
              _image == null
                  ? Text('No image selected.')
                  : _buildImage(),
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _pickImage(source: ImageSource.camera),
                      child: Text('Capture Image'),
                    ),
                    ElevatedButton(
                      onPressed: () => _pickImage(source: ImageSource.gallery),
                      child: Text('Select Image from Gallery'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    double maxHeight = MediaQuery.of(context).size.height * 0.5;
    double maxWidth = MediaQuery.of(context).size.width * 0.9;

    double imageAspectRatio = _imageWidth! / _imageHeight!;
    double containerAspectRatio = maxWidth / maxHeight;

    double displayWidth;
    double displayHeight;

    if (imageAspectRatio > containerAspectRatio) {
      displayWidth = maxWidth;
      displayHeight = maxWidth / imageAspectRatio;
    } else {
      displayHeight = maxHeight;
      displayWidth = maxHeight * imageAspectRatio;
    }

    return Center(
      child: Container(
        width: displayWidth,
        height: displayHeight,
        child: Image.file(_image!),
      ),
    );
  }

  Widget _buildRecognitionList() {
    var _width = MediaQuery.of(context).size.width;
    var _padding = 20.0;
    var _labelWidth = 200.0;
    var _labelConfidence = 50.0;
    var _barWidth = _width - _labelWidth - _labelConfidence - _padding * 2.0;

    return Container(
      height: 150,
      child: ListView.builder(
        itemCount: _results!.length,
        itemBuilder: (context, index) {
          if (_results!.length > index) {
            return Container(
              height: 40,
              child: Row(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(left: _padding, right: _padding),
                    width: _labelWidth,
                    child: Text(
                      _results![index]['label'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: _barWidth,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      value: _results![index]['confidence'],
                    ),
                  ),
                  Container(
                    width: _labelConfidence,
                    child: Text(
                      (_results![index]['confidence'] * 100).toStringAsFixed(1) + '%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}