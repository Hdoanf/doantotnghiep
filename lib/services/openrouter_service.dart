import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/health_record.dart';

class OpenRouterService {
  final String _apiKey = Env.openRouterApiKey;
  final String _model = "meta-llama/llama-3.1-8b-instruct:free";

  Future<String> getChatResponse(List<HealthRecord> history, String userMessage) async {
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");
    
    final context = _buildContext(history);
    
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $_apiKey",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:8080", // Yêu cầu bắt buộc của OpenRouter
        "X-Title": "HF Health App",
      },
      body: jsonEncode({
        "model": _model,
        "messages": [
          {"role": "system", "content": "Bạn là một trợ lý sức khỏe chuyên nghiệp. Trả lời ngắn gọn bằng tiếng Việt."},
          {"role": "user", "content": "$context\n\nCâu hỏi: $userMessage"}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception("Lỗi kết nối OpenRouter: ${response.body}");
    }
  }

  String _buildContext(List<HealthRecord> history) {
    if (history.isEmpty) return "Hiện chưa có dữ liệu lịch sử sức khỏe.";
    String context = "Dữ liệu sức khỏe gần đây:\n";
    for (var record in history.take(5)) {
      context += "- Ngày ${record.date.day}/${record.date.month}: ${record.indicators.toString()}\n";
    }
    return context;
  }
}
