import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/config/api_keys.dart';

final geminiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiService {
  final Dio _dio = Dio();

  // 🔑 API KEY - Now imported from config file
  static const String _geminiKey = ApiKeys.geminiApiKey;

  // 📝 SYSTEM PROMPT (Context about the app)
  static const String _systemPrompt = """
You are the AI Assistant for the 'Support Chat' application (also known as Chatapp). 
Your goal is to help users navigate and use the application's features.

Here is what this app can do:
1. **Real-time Messaging**: Users can chat 1-on-1 or create group chats with multiple members.
2. **Status Stories**: Users can post updates (images/text) that disappear, just like WhatsApp Status.
3. **Notes & Reminders**: A dedicated section to save personal notes and set reminders for important tasks.
4. **AI Assistant**: That's you! You are integrated into the bottom bar to help users with queries, image analysis, and voice commands.
5. **Profile Management**: Users can update their profile picture (DP), bio, and business information.
6. **Media Sharing**: Supports sending images and files in chats, powered by Cloudinary.
7. **Security**: Uses Firebase Authentication and secure Firestore rules.

When users ask about the app, explain these features clearly and helpfully.
""";

  /// Use Gemini 2.5 Flash with System Context
  Future<String> getResponse(String prompt) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true,
        ),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': "Context: $_systemPrompt\n\nUser Question: $prompt"},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7, // Lower temperature for more factual help
            'topP': 0.95,
            'topK': 64,
            'maxOutputTokens': 8192,
          },
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
        return 'No response generated.';
      } else {
        return 'Error: ${response.data['error']?['message'] ?? 'Unknown error'}';
      }
    } catch (e) {
      return 'Connection Error: $e';
    }
  }

  /// Gemini Vision with System Context
  Future<String> getResponseWithImage(
    String prompt,
    List<Uint8List> images,
  ) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiKey',
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      "Context: $_systemPrompt\n\nImage Analysis Request: $prompt",
                },
                ...images.map(
                  (bytes) => {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Encode(bytes),
                    },
                  },
                ),
              ],
            },
          ],
        },
      );

      if (response.statusCode == 200) {
        return response.data['candidates'][0]['content']['parts'][0]['text'];
      }
      return 'Vision Error: ${response.data['error']?['message'] ?? response.statusMessage}';
    } catch (e) {
      return 'Vision Error: $e';
    }
  }
}
