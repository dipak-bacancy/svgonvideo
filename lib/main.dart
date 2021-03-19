import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:svgonvideo/video.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
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

  double _rotation = 0.0;

  Offset _offset = Offset(0, 0);

  double _scale = 1;

  _loadSvgFromAsset() async {
    final filename = 'panda.png';
    final bytes = await rootBundle.load("assets/panda.png");
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

    final outputPath = dir.path + "/" + filename;

    final localCommand =
        "-i '$videoPath' -i '$imgpath' -filter_complex '[1:v]format=bgra,rotate=$_rotation:c=none:ow=rotw($_rotation):oh=roth($_rotation)[rotate];[rotate]scale=300:300[scale];[0:v][scale] overlay=${_offset.dx * 2}:${_offset.dy * 2}' -q:v 0 -q:a 0 -r 60 '$outputPath'";
    print('------------- $localCommand');

    FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    await _flutterFFmpeg.execute(localCommand).then((value) {
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
        clipChild: true,
        shouldScale: false,
        focalPointAlignment: Alignment.center,
        onMatrixUpdate: (m, tm, sm, rm) {
          notifier.value = m;

          final val = MatrixGestureDetector.decomposeToValues(m);

          _offset = val.translation;
          _scale = val.scale;
          _rotation = val.rotation;
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
                    height: 150,
                    width: 150,
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
