import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../config/health_constants.dart';
import '../models/health_record.dart';

class GeminiService {
  final String _apiKey = Env.groqApiKey;

  final String _baseUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  final String _model = "meta-llama/llama-4-scout-17b-16e-instruct";

  Future<String> getHealthAdvice(
    List<HealthRecord> history,
    String userMessage,
  ) async {
    final context = _buildContext(history);
    final prompt =
        "$context\n\nNgười dùng hỏi: $userMessage\n"
        "Trả lời bằng tiếng Việt theo cách dễ hiểu, đủ chi tiết để người dùng làm theo. "
        "Cấu trúc câu trả lời gồm: nhận định chính, giải thích ngắn, các bước nên làm, khi nào cần đi khám. "
        "Không dùng markdown phức tạp như ### hoặc **. Chỉ dùng tiêu đề ngắn và gạch đầu dòng khi cần. "
        "Không chẩn đoán chắc chắn và không thay thế bác sĩ.";
    return _callGemini(prompt);
  }

  Future<String> generateSummaryReport(List<HealthRecord> history) async {
    if (history.isEmpty) return "Chưa có dữ liệu để tạo báo cáo.";
    final context = _buildContext(history);
    final prompt =
        "$context\n\nTạo báo cáo tóm tắt sức khỏe bằng tiếng Việt. "
        "Chia thành 3 mục ngắn: Tổng quan, Điểm cần theo dõi, Gợi ý.";
    return _callGemini(prompt);
  }

  Future<Map<String, double>> parseOCRText(String text) async {
    final supportedIndicators = HealthConstants.scanIndicators.entries
        .map((entry) {
          final config = entry.value;
          return "- ${entry.key}: ${config['name']} (${config['unit']})";
        })
        .join('\n');

    final prompt =
        """
    Bạn là một chuyên gia phân tích kết quả xét nghiệm y tế. 
    Nhiệm vụ: Trích xuất tất cả chỉ số sức khỏe có trong văn bản OCR và trả về JSON.
    
    Chỉ trả về các key app hỗ trợ dưới đây, bỏ qua mọi chỉ số khác:
    $supportedIndicators

    Yêu cầu:
    1. Chỉ trả về DUY NHẤT mã JSON, không thêm giải thích.
    2. JSON có dạng: {"key": value}. Ví dụ: {"glucose": 5.6, "systolic": 120}.
    3. Nếu không tìm thấy chỉ số nào, trả về {}.
    4. Hãy tìm cả tên tiếng Việt, tiếng Anh, ký hiệu viết tắt và cách viết thường gặp.
    5. Nếu thấy huyết áp dạng 120/80 mmHg, trả về {"systolic": 120, "diastolic": 80}.
    6. Không tự suy đoán chỉ số không xuất hiện rõ trong OCR.

    Văn bản OCR:
    $text
    """;

    try {
      final responseText = await _callGemini(prompt);
      // Loại bỏ các ký tự thừa như ```json ... ```
      String cleanText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Tìm vị trí của dấu { và } đầu tiên/cuối cùng để trích xuất đúng JSON
      int start = cleanText.indexOf('{');
      int end = cleanText.lastIndexOf('}');
      if (start != -1 && end != -1) {
        cleanText = cleanText.substring(start, end + 1);
      }

      final Map<String, dynamic> decoded = json.decode(cleanText);
      return _filterSupportedIndicators(decoded);
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
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.45,
          "max_tokens": 4096,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final text = data['choices'][0]['message']['content'] as String;
        final finishReason = data['choices'][0]['finish_reason'] ?? '';
        if (finishReason == 'length') {
          debugPrint('⚠️ AI response was truncated due to max_tokens limit');
        }
        return text;
      } else {
        if (response.statusCode == 429) {
          throw Exception(
            'Đã hết quota AI tạm thời. Vui lòng chờ một lúc rồi thử lại.',
          );
        }
        final errorMsg = data['error']?['message'] ?? 'Unknown error';
        throw Exception("Lỗi AI (${response.statusCode}): $errorMsg");
      }
    } catch (e) {
      rethrow;
    }
  }

  Map<String, double> _filterSupportedIndicators(Map<String, dynamic> decoded) {
    final supportedKeys = HealthConstants.scanIndicators.keys.toSet();
    final normalized = <String, double>{};

    for (final entry in decoded.entries) {
      final key = _normalizeIndicatorKey(entry.key);
      if (!supportedKeys.contains(key)) continue;

      final rawValue = entry.value;
      final value = rawValue is num
          ? rawValue.toDouble()
          : double.tryParse(rawValue.toString().replaceAll(',', '.'));
      if (value == null) continue;

      normalized[key] = value;
    }

    return normalized;
  }

  String _normalizeIndicatorKey(String key) {
    final normalized = key.trim().toLowerCase();
    return switch (normalized) {
      'blood_glucose' || 'duong_huyet' || 'đường_huyết' => 'glucose',
      'total_cholesterol' || 'cholesterol_total' => 'cholesterol',
      'hdl_cholesterol' || 'hdl-c' || 'hdl-c cholesterol' => 'hdl',
      'ldl_cholesterol' || 'ldl-c' || 'ldl-c cholesterol' => 'ldl',
      'triglyceride' || 'triglycerid' => 'triglycerides',
      'sys' || 'sbp' || 'huyet_ap_tam_thu' || 'huyết_ap_tâm_thu' => 'systolic',
      'dia' ||
      'dbp' ||
      'huyet_ap_tam_truong' ||
      'huyết_ap_tâm_trương' => 'diastolic',
      'pulse' || 'hr' || 'nhip_tim' || 'nhịp_tim' => 'heart_rate',
      'spo2' || 'oxygen_saturation' => 'spO2',
      'can_nang' || 'cân_nặng' => 'weight',
      'chieu_cao' || 'chiều_cao' => 'height',
      _ => normalized,
    };
  }

  String _buildContext(List<HealthRecord> history) {
    if (history.isEmpty) return "Bạn là trợ lý sức khỏe.";
    final buffer = StringBuffer(
      "Lịch sử sức khỏe của người dùng (${history.length} bản ghi, mới nhất trước):\n",
    );

    var usedChars = buffer.length;
    const maxContextChars = 6000;

    var includedCount = 0;
    for (final record in history) {
      final line = StringBuffer(
        "- ${record.date.day}/${record.date.month}/${record.date.year}: ",
      );
      if (record.indicators.isEmpty) {
        line.write("không có chỉ số");
      } else {
        line.write(
          record.indicators.entries
              .map((entry) {
                return "${entry.key}=${entry.value}";
              })
              .join(", "),
        );
      }
      if (record.note != null && record.note!.isNotEmpty) {
        line.write(" | ghi chú: ${record.note}");
      }
      line.write("\n");

      if (usedChars + line.length > maxContextChars) {
        buffer.writeln(
          "- Còn ${history.length - includedCount} bản ghi cũ hơn không đưa vào vì giới hạn ngữ cảnh.",
        );
        break;
      }

      buffer.write(line.toString());
      usedChars += line.length;
      includedCount++;
    }

    return buffer.toString();
  }
}
