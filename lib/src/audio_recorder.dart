/*
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecorder {
  FlutterSoundRecorder? _recorder;
  String? _filePath;

  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio_record.aac';
    await _recorder!.startRecorder(toFile: _filePath);
  }

  Future<String?> stopRecording() async {
    await _recorder!.stopRecorder();
    return _filePath;
  }

  void dispose() {
    _recorder!.closeRecorder();
  }
}
*/
