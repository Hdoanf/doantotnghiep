import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/health_record.dart';

class GeminiService {
  final String _apiKey = "AIzaSyBoo93ft3lgNsdtuHA7HYYW74xTeLHMt4g";
  
  // Sử dụng model name chính xác từ curl của bạn
  final String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";

  Future<String> getHealthAdvice(List<HealthRecord> history, String userMessage) async {
    final context = _buildContext(history);
    final prompt = "$context\n\nNgười dùng hỏi: $userMessage\nHãy trả lời bằng tiếng Việt.";
    return _callGemini(prompt);
  }

  Future<String> generateSummaryReport(List<HealthRecord> history) async {
    if (history.isEmpty) return "Chưa có dữ liệu để tạo báo cáo.";
    final context = _buildContext(history);
    final prompt = "$context\n\nHãy tạo báo cáo tóm tắt sức khỏe chuyên nghiệp bằng tiếng Việt.";
    return _callGemini(prompt);
  }

  Future<Map<String, double>> parseOCRText(String text) async {
    final prompt = """
    Bạn là một chuyên gia phân tích kết quả xét nghiệm y tế. 
    Nhiệm vụ: Trích xuất các chỉ số từ văn bản OCR sau đây và trả về định dạng JSON.
    
    Các chỉ số cần tìm (Key trong JSON):
    - glucose (Đường huyết)
    - cholesterol (Cholesterol toàn phần)
    - hdl (HDL-Cho)
    - ldl (LDL-Cho)
    - triglycerides (Triglycerid)
    - systolic (Huyết áp tâm thu)
    - diastolic (Huyết áp tâm trương)
    - heart_rate (Nhịp tim)
    - weight (Cân nặng)
    - height (Chiều cao)

    Yêu cầu:
    1. Chỉ trả về DUY NHẤT mã JSON, không thêm giải thích.
    2. JSON có dạng: {"key": value}. Ví dụ: {"glucose": 5.6, "systolic": 120}.
    3. Nếu không tìm thấy chỉ số nào, trả về {}.
    4. Hãy tìm cả tên tiếng Việt và ký hiệu viết tắt.

    Văn bản OCR:
    $text
    """;
    
    try {
      final responseText = await _callGemini(prompt);
      // Loại bỏ các ký tự thừa như ```json ... ```
      String cleanText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Tìm vị trí của dấu { và } đầu tiên/cuối cùng để trích xuất đúng JSON
      int start = cleanText.indexOf('{');
      int end = cleanText.lastIndexOf('}');
      if (start != -1 && end != -1) {
        cleanText = cleanText.substring(start, end + 1);
      }

      final Map<String, dynamic> decoded = json.decode(cleanText);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      debugPrint('Lỗi Parsing AI: $e');
      return {};
    }
  }

  Future<String> _callGemini(String prompt) async {
    final url = Uri.parse(_baseUrl);
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey, // Gửi key qua header như curl
        },
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": prompt}]
          }]
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        String errorMsg = data['error'] != null ? data['error']['message'] : "Unknown error";
        throw Exception("Lỗi AI (${response.statusCode}): $errorMsg");
      }
    } catch (e) {
      rethrow;
    }
  }

  String _buildContext(List<HealthRecord> history) {
    if (history.isEmpty) return "Bạn là trợ lý sức khỏe.";
    String context = "Lịch sử sức khỏe:\n";
    for (var record in history.take(3)) {
      context += "- ${record.date.day}/${record.date.month}: ${record.indicators.toString()}\n";
    }
    return context;
  }
}
