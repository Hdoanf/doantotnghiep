import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class BodyMetricsInput extends StatefulWidget {
  const BodyMetricsInput({super.key});

  @override
  State<BodyMetricsInput> createState() => _BodyMetricsInputState();
}

class _BodyMetricsInputState extends State<BodyMetricsInput> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  bool _isSaving = false;

  void _save() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final indicators = <String, double>{};
    
    if (_weightController.text.isNotEmpty) {
      indicators['weight'] = double.tryParse(_weightController.text) ?? 0;
    }
    if (_heightController.text.isNotEmpty) {
      indicators['height'] = double.tryParse(_heightController.text) ?? 0;
    }

    if (indicators.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final record = HealthRecord(
        id: '',
        userId: user.uid,
        date: DateTime.now(),
        type: RecordType.bodyMetrics,
        indicators: indicators,
      );
      await FirestoreService().addHealthRecord(record);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.secondaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chỉ Số Cơ Thể', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Manrope')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập chỉ số cơ thể', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'Manrope', color: AppTheme.textColor)),
            const SizedBox(height: 8),
            const Text('Vui lòng nhập các chỉ số sức khỏe của bạn để hệ thống theo dõi.', style: TextStyle(fontSize: 16, color: AppTheme.secondaryTextColor)),
            const SizedBox(height: 24),
            
            // Cân nặng
            _buildBentoCard(
              icon: Icons.monitor_weight,
              iconColor: AppTheme.accentColor,
              title: 'Cân nặng',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CÂN NẶNG HIỆN TẠI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryTextColor, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Manrope'),
                          decoration: InputDecoration(
                            hintText: '65.5',
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('kg', style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Chiều cao
            _buildBentoCard(
              icon: Icons.height,
              iconColor: AppTheme.infoColor,
              title: 'Chiều cao',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CHIỀU CAO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryTextColor, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Manrope'),
                          decoration: InputDecoration(
                            hintText: '170',
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('cm', style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu kết quả', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Manrope')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mutedTextColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Manrope', color: AppTheme.textColor)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
