import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tflite_service.dart';
import 'dart:async';

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
  int _frames = 0;
  double _fps = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _tfliteHelper.loadModel();
    _startFPSTimer();
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
        _frames++;
      });

      setState(() {});
    } catch (e) {
      setState(() {
        _cameraAvailable = false;
      });
    }
  }

  Future<void> _runModelOnFrame(CameraImage image) async {
    // Run inference in a separate Future
    Future(() async {
      var results = await _tfliteHelper.classifyImageFromCamera(image);
      setState(() {
        _results = results;
      });
      _isDetecting = false;
    });
  }

  void _startFPSTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _fps = _frames.toDouble();
        _frames = 0;
      });
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tfliteHelper.disposeModel();
    _timer?.cancel();
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
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          'FPS: ${_fps.toStringAsFixed(1)}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
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