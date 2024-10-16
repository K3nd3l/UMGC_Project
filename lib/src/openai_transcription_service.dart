/*
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> transcribeAudio(String filePath) async {
  String apiKey = 'your-openai-api-key';  // Replace with your OpenAI API key
  String apiUrl = 'https://api.openai.com/v1/audio/transcriptions';  // OpenAI transcription API

  var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
  request.headers['Authorization'] = 'Bearer $apiKey';
  request.files.add(await http.MultipartFile.fromPath('file', filePath));
  request.fields['model'] = 'whisper-1';  // Replace with your preferred model

  var response = await request.send();
  if (response.statusCode == 200) {
    var responseData = await http.Response.fromStream(response);
    var jsonData = jsonDecode(responseData.body);
    return jsonData['text'];
  } else {
    throw Exception('Failed to transcribe audio.');
  }
}
*/