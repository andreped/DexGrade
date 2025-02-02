import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';

class TFLiteHelper {
  late Interpreter _interpreter;
  late List<String> _labels;
  late List<int> _inputShape;
  late List<int> _outputShape;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
    _labels = await _loadLabels('assets/models/labels.txt');

    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;
  }

  Future<List<String>> _loadLabels(String path) async {
    final rawLabels = await rootBundle.loadString(path);
    return rawLabels.split('\n');
  }

  Future<List<Map<String, dynamic>>> classifyImage(File image) async {
    final img.Image imageInput = img.decodeImage(image.readAsBytesSync())!;
    final img.Image resizedImage = img.copyResize(imageInput, width: _inputShape[1], height: _inputShape[2]);

    final input = _imageToByteListFloat32(resizedImage, _inputShape[1], _inputShape[2]);

    final output = List.filled(_outputShape[1], 0.0).reshape([1, _outputShape[1]]);

    _interpreter.run(input, output);

    final labeledProb = Map<String, double>.fromIterables(_labels, output[0]);

    final sortedEntries = labeledProb.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value));

    return sortedEntries
        .take(5)
        .map((entry) => {'label': entry.key, 'confidence': entry.value})
        .toList();
  }

  Future<List<Map<String, dynamic>>> classifyImageFromCamera(CameraImage image) async {
    final img.Image imageInput = _convertCameraImage(image);
    final img.Image resizedImage = img.copyResize(imageInput, width: _inputShape[1], height: _inputShape[2]);

    final input = _imageToByteListFloat32(resizedImage, _inputShape[1], _inputShape[2]);

    final output = List.filled(_outputShape[1], 0.0).reshape([1, _outputShape[1]]);

    _interpreter.run(input, output);

    final labeledProb = Map<String, double>.fromIterables(_labels, output[0]);

    final sortedEntries = labeledProb.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value));

    return sortedEntries
        .take(5)
        .map((entry) => {'label': entry.key, 'confidence': entry.value})
        .toList();
  }

  img.Image _convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image imgImage = img.Image(width, height);

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        final int pixel = image.planes[0].bytes[i * width + j];
        imgImage.setPixel(j, i, img.getColor(pixel, pixel, pixel));
      }
    }

    return imgImage;
  }

  Uint8List _imageToByteListFloat32(img.Image image, int inputWidth, int inputHeight) {
    final convertedBytes = Float32List(1 * inputWidth * inputHeight * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (int i = 0; i < inputWidth; i++) {
      for (int j = 0; j < inputHeight; j++) {
        final pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - 127.5) / 127.5;
        buffer[pixelIndex++] = (img.getGreen(pixel) - 127.5) / 127.5;
        buffer[pixelIndex++] = (img.getBlue(pixel) - 127.5) / 127.5;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future<void> disposeModel() async {
    _interpreter.close();
  }
}