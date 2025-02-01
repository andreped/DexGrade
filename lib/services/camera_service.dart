import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'tflite_service.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  List<Map<String, dynamic>>? _results;
  final TFLiteHelper _tfliteHelper = TFLiteHelper();

  @override
  void initState() {
    super.initState();
    _tfliteHelper.loadModel();
  }

  @override
  void dispose() {
    _tfliteHelper.disposeModel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _classifyImage(File(pickedFile.path));
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Capture Image'),
            ),
            SizedBox(height: 20),
            _results == null
                ? Container()
                : Column(
                    children: _results!.map((result) {
                      return Text(
                        "${result['label']} - ${(result['confidence'] * 100).toStringAsFixed(2)}%",
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}