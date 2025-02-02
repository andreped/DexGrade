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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _results == null
                  ? Container()
                  : Column(
                      children: _results!.map((result) {
                        return Text(
                          "${result['label']} - ${(result['confidence'] * 100).toStringAsFixed(2)}%",
                        );
                      }).toList(),
                    ),
              SizedBox(height: 20),
              _image == null
                  ? Text('No image selected.')
                  : AspectRatio(
                      aspectRatio: _imageWidth! / _imageHeight!,
                      child: Image.file(_image!),
                    ),
              SizedBox(height: 20),
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
      ),
    );
  }
}