import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
}
