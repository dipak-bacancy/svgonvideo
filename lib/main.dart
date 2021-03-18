import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:svgonvideo/video.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

import 'dart:math';

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

  double _angel = 0.0;

  Offset _offset = Offset(0, 0);

  double _xScale = 0;
  double _yScale = 0;

  _loadSvgFromAsset() async {
    final filename = 'panda.svg';
    final bytes = await rootBundle.load("assets/panda.svg");
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final path = '$dir/$filename';
    final buffer = bytes.buffer;

    print(path);

    await File(path).writeAsBytes(
        buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    File file = File('$dir/$filename');
    print('Loaded file ${file.path}');

    return file.path;
  }

  Future<String> merge() async {
    FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.video);

    print(result?.files.single.path);

    String videoPath = result?.files.single.path;

    final filename = '${DateTime.now().millisecondsSinceEpoch}_output.mp4';

    Directory dir = await getExternalStorageDirectory();

    final imgpath = await _loadSvgFromAsset();

    // print(dir.path + '/' + filename);
    final outputPath = dir.path + "/" + filename;

    // String imgOverlayCommand =
    //     '-i $videoPath -i imagepath -filter_complex "[0:v][1:v] overlay=-300:-300" $outputPath';

    String cmd =
        '''-i $videoPath -i $imgpath -filter_complex "[1:v] rotate=$_angel:c=none:ow=rotw(iw):oh=roth(ih) [rotate];[0:v][rotate] overlay=${_offset.dx}:${_offset.dx}" -codec:a copy $outputPath''';

    print('------------- $cmd');

    FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    await _flutterFFmpeg.execute(cmd).then((value) {
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

          final rotation = m.getRotation();
          final rad = asin(rotation[1]);
          // final angel = degree < 0 ? (360 + degree) : degree;

          final traslation = m.getTranslation();

          // setting parameters
          _xScale = m.getRow(0)[0];
          _yScale = m.getRow(0)[0];
          _angel = rad;
          _offset = Offset(traslation[0], traslation[1]);
        },
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
                    height: 200,
                    // height: 100,
                    // width: 100,
                  )
                ],
              ),
            );
          },
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
