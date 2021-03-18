import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:svgonvideo/video.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TransformDemo(),
    );
  }
}

class TransformDemo extends StatefulWidget {
  @override
  _TransformDemoState createState() => _TransformDemoState();
}

class _TransformDemoState extends State<TransformDemo> {
  GlobalKey _globalKey = new GlobalKey();

  Future<String> _capturePng() async {
    try {
      print('inside');
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData.buffer;

      final filename = '${DateTime.now().millisecondsSinceEpoch}_svg.png';

      Directory dir = await getExternalStorageDirectory();

      print(dir.path + '/' + filename);

      final path = dir.path + "/" + filename;

      await new File(path)
          .writeAsBytes(buffer.asUint8List(
              byteData.offsetInBytes, byteData.lengthInBytes))
          .then((value) => print('written'));

      File file = File(path);
      print('Loaded file ${file.path}');

      return file.path;
    } catch (e) {
      print(e);
    }
  }

  Future<String> merge() async {
    FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.video);

    print(result?.files.single.path);

    String videoPath = result?.files.single.path;

    String imagepath = await _capturePng();

    final filename = '${DateTime.now().millisecondsSinceEpoch}_output.mp4';

    Directory dir = await getExternalStorageDirectory();

    // print(dir.path + '/' + filename);
    final outputPath = dir.path + "/" + filename;

    // File file = File(result?.files.single.path);

    // Directory dir = await getExternalStorageDirectory();

    String imgOverlayCommand =
        '-i $videoPath -i $imagepath -filter_complex "[0:v][1:v] overlay=-300:-300" $outputPath';

    print('------------- $imgOverlayCommand');

    FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    await _flutterFFmpeg.execute(imgOverlayCommand).then((value) {
      print(" x $value} outputPath1 $outputPath");
    }).catchError((e) {
      print("error in 1 is $e");
    });

    return outputPath;
  }

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());
    return Scaffold(
      body: MatrixGestureDetector(
        onMatrixUpdate: (m, tm, sm, rm) {
          notifier.value = m;
        },
        child: RepaintBoundary(
          key: _globalKey,
          child: AnimatedBuilder(
            animation: notifier,
            builder: (ctx, child) {
              return Transform(
                transform: notifier.value,
                child: Stack(
                  children: <Widget>[
                    Container(),
                    SvgPicture.asset(
                      'assets/panda.svg',
                      semanticsLabel: 'Acme Logo',
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // final res = await _capturePng();
          final outpath = await merge();

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VideoApp(
                        outpath,
                      )));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
