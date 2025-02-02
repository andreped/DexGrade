import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tflite_service.dart';

class CameraStreamScreen extends StatefulWidget {
  @override
  _CameraStreamScreenState createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  List<Map<String, dynamic>>? _results;
  final TFLiteHelper _tfliteHelper = TFLiteHelper();
  bool _cameraAvailable = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _tfliteHelper.loadModel();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraAvailable = false;
        });
        return;
      }
      final camera = cameras.first;

      _cameraController = CameraController(camera, ResolutionPreset.medium);
      await _cameraController?.initialize();

      _cameraController?.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _runModelOnFrame(image);
        }
      });

      setState(() {});
    } catch (e) {
      setState(() {
        _cameraAvailable = false;
      });
    }
  }

  Future<void> _runModelOnFrame(CameraImage image) async {
    var results = await _tfliteHelper.classifyImageFromCamera(image);
    setState(() {
      _results = results;
    });
    _isDetecting = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tfliteHelper.disposeModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Pokémon Card Detection'),
      ),
      body: _cameraAvailable
          ? (_cameraController == null
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    CameraPreview(_cameraController!),
                    _results == null
                        ? Container()
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              color: Colors.black54,
                              height: 150,
                              child: _buildRecognitionList(),
                            ),
                          ),
                  ],
                ))
          : Center(
              child: Text(
                'No camera available',
                style: TextStyle(fontSize: 24, color: Colors.red),
              ),
            ),
    );
  }

  Widget _buildRecognitionList() {
    var _width = MediaQuery.of(context).size.width;
    var _padding = 20.0;
    var _labelWidth = 200.0;
    var _labelConfidence = 50.0;
    var _barWidth = _width - _labelWidth - _labelConfidence - _padding * 2.0;

    return ListView.builder(
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
    );
  }
}