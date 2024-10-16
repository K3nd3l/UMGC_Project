import 'dart:io';
import 'dart:convert'; // Add this import for JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transcriber',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterSoundRecorder _recorder;
  bool _isRecording = false;
  String? _audioFilePath;
  String _transcription = 'Transcription will appear here...';
  String _translatedText = 'Transcription will appear here...';
  String _selectedLanguage = 'en'; // Default language

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _init();
  }

  Future<void> _init() async {
    await _recorder.openRecorder();
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
      status = await Permission.microphone.status;
    }
    if (!status.isGranted) {
      print("Microphone permission is not granted");
    }
  }

  Future<void> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _audioFilePath = '${tempDir.path}/recording.wav';
      await _recorder.startRecorder(
        toFile: _audioFilePath,
        codec: Codec.pcm16WAV,
      );
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      await transcribeAudio();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

Future<void> transcribeAudio() async {
  if (_audioFilePath == null) return;

  var url = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
  var request = http.MultipartRequest('POST', url)
    ..headers['Authorization'] = 'Bearer key_goes_here'
    ..fields['model'] = 'whisper-1'
    ..fields['language'] = 'en' // Specify English transcription
    ..files.add(await http.MultipartFile.fromPath('file', _audioFilePath!));

  var response = await request.send();
  if (response.statusCode == 200) {
    var responseData = await response.stream.toBytes();
    Map<String, dynamic> parsedResponse = json.decode(String.fromCharCodes(responseData));
    setState(() {
      _transcription = parsedResponse['text'] ?? 'No transcription available';
    });
    await saveTranscription(parsedResponse['text']);
    await translateText(_transcription); // Call the translate function after transcription
  } else {
    setState(() {
      _transcription = 'Failed to transcribe audio: ${response.statusCode}';
    });
  }
}



Future<void> saveTranscription(String? transcription) async {
  if (transcription == null) return;

  String timestamp = DateTime.now().toString();
  String transcriptionWithTimestamp = '[$timestamp] $transcription';
  String filePath = '/sdcard/Documents/recording.txt';

  File file = File(filePath);
  await file.writeAsString(transcriptionWithTimestamp);
  print('Transcription saved to: $filePath');
}


  Future<void> translateText(String text) async {
    if (text.isEmpty) return;

    var translationUrl = Uri.parse('https://api.openai.com/v1/chat/completions');
    var response = await http.post(
      translationUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer key_goes_here',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a translation assistant.'
          },
          {
            'role': 'user',
            'content': 'Translate the following text to ${_selectedLanguage == 'es' ? 'Spanish' : _selectedLanguage == 'fr' ? 'French' : 'English'}: "$text"'
          }
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      var translatedData = json.decode(response.body);
      setState(() {
        _translatedText = translatedData['choices'][0]['message']['content'] ?? 'Translation failed';
      });
    } else {
      setState(() {
        _translatedText = 'Failed to translate text: ${response.statusCode}';
      });
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Transcriber'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRecording ? 'Recording...' : 'Press to Start Recording',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            SizedBox(height: 20),
            Text(
              'Transcription:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              _translatedText, // Show translated text here
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedLanguage,
              items: [
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Text('English'),
                ),
                DropdownMenuItem<String>(
                  value: 'es',
                  child: Text('Español'),
                ),
                DropdownMenuItem<String>(
                  value: 'fr',
                  child: Text('Français'),
                ),
              ],
              onChanged: (String? newValue) async {
                setState(() {
                  _selectedLanguage = newValue!;
                });
                await translateText(_transcription); // Translate text when language changes
              },
            ),

          ],
        ),
      ),
    );
  }
}
