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
      backgroundColor: Colors.black,
      body: _isProcessing ? _buildProcessing() : _buildReady(),
    );
  }

  Widget _buildProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.1),
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
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhận diện và phân tích chỉ số',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReady() {
    return Stack(
      children: [
        // Simulated Camera Feed Background
        Positioned.fill(
          child: Container(
            color: const Color(0xFF1A1A1A),
            child: Opacity(
              opacity: 0.4,
              child: Image.network(
                'https://images.unsplash.com/photo-1579684385127-1ef15d508118?q=80&w=2000&auto=format&fit=crop',
                fit: BoxFit.cover,
                // Apply a grayscale/luminosity filter to mimic the design
                color: Colors.white,
                colorBlendMode: BlendMode.luminosity,
              ),
            ),
          ),
        ),

        // Top Overlay Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconButton(Icons.close, () {
                  // Usually goes back, but maybe not in bottom nav
                }),
                _iconButton(Icons.flash_off, () {}),
              ],
            ),
          ),
        ),

        // Main Viewfinder Area
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instruction Text
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Căn chỉnh phiếu xét nghiệm vào khung hình để quét',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Scanning Guide Reticle
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    children: [
                      // Dark overlay outside reticle is hard to do cleanly without CustomPainter,
                      // we'll just use the brackets.
                      
                      // Top Left
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _cornerBracket(
                          top: true,
                          left: true,
                        ),
                      ),
                      // Top Right
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _cornerBracket(
                          top: true,
                          left: false,
                        ),
                      ),
                      // Bottom Left
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _cornerBracket(
                          top: false,
                          left: true,
                        ),
                      ),
                      // Bottom Right
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _cornerBracket(
                          top: false,
                          left: false,
                        ),
                      ),
                      // Center Crosshair
                      const Center(
                        child: Opacity(
                          opacity: 0.2,
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 32, bottom: 48, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Button
                _bottomIconButton(
                  icon: Icons.photo_library_outlined,
                  onTap: () => _scanImage(ImageSource.gallery),
                ),
                
                // Shutter Button
                GestureDetector(
                  onTap: () => _scanImage(ImageSource.camera),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Switch Camera Button
                _bottomIconButton(
                  icon: Icons.cameraswitch_outlined,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _bottomIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _cornerBracket({required bool top, required bool left}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppTheme.primaryColor, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppTheme.primaryColor, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: AppTheme.primaryColor, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: AppTheme.primaryColor, width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(12) : Radius.zero,
          topRight: top && !left ? const Radius.circular(12) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}
