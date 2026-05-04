import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
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
        child: _isProcessing ? _buildProcessing() : _buildReady(),
      ),
    );
  }

  Widget _buildProcessing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.accentLightColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Đang xử lý bằng AI...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nhận diện và phân tích chỉ số',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.mutedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildReady() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scan illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Quét phiếu xét nghiệm',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tự động nhận diện chỉ số từ giấy xét nghiệm\nbằng AI và OCR thông minh',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mutedTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.camera_alt_rounded,
                  label: 'Máy ảnh',
                  subtitle: 'Chụp trực tiếp',
                  onTap: () => _scanImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _actionCard(
                  icon: Icons.photo_library_rounded,
                  label: 'Thư viện',
                  subtitle: 'Chọn ảnh có sẵn',
                  onTap: () => _scanImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.accentLightColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
