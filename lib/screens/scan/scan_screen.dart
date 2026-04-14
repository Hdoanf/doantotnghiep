import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import '../../services/gemini_service.dart';
import 'scan_result_confirm_screen.dart';
import '../../models/health_record.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ocrService = OCRService();
  final _geminiService = GeminiService();
  bool _isProcessing = false;

  void _scanImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isProcessing = true);
    try {
      // 1. OCR Step
      final text = await _ocrService.recognizeText(image);
      
      // 2. AI Parsing Step
      final indicators = await _geminiService.parseOCRText(text);
      
      if (mounted) {
        if (indicators.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI không nhận diện được chỉ số nào. Bạn hãy thử chụp rõ nét hơn hoặc nhập tay nhé.'),
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanResultConfirmScreen(
                initialIndicators: indicators,
                type: RecordType.bloodTest,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi quét: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét kết quả xét nghiệm')),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang xử lý bằng AI...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner, size: 100, color: Colors.blue),
                  const SizedBox(height: 32),
                  const Text('Chụp ảnh hoặc chọn từ thư viện', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Tự động nhận diện chỉ số từ giấy xét nghiệm',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _scanImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Máy ảnh'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _scanImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Thư viện'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
