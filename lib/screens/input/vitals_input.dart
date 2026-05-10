import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../scan/ble_device_scan_screen.dart';

class VitalsInput extends StatefulWidget {
  const VitalsInput({super.key});

  @override
  State<VitalsInput> createState() => _VitalsInputState();
}

class _VitalsInputState extends State<VitalsInput> {
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _spO2Controller = TextEditingController();
  
  bool _isSaving = false;

  void _save() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final indicators = <String, double>{};
    
    if (_systolicController.text.isNotEmpty) {
      indicators['systolic'] = double.tryParse(_systolicController.text) ?? 0;
    }
    if (_diastolicController.text.isNotEmpty) {
      indicators['diastolic'] = double.tryParse(_diastolicController.text) ?? 0;
    }
    if (_heartRateController.text.isNotEmpty) {
      indicators['heart_rate'] = double.tryParse(_heartRateController.text) ?? 0;
    }
    if (_spO2Controller.text.isNotEmpty) {
      indicators['spO2'] = double.tryParse(_spO2Controller.text) ?? 0;
    }

    if (indicators.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final record = HealthRecord(
        id: '',
        userId: user.uid,
        date: DateTime.now(),
        type: RecordType.vitals,
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
        title: const Text('Nhập Sinh Tồn', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Manrope')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập chỉ số sinh tồn', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'Manrope', color: AppTheme.textColor)),
            const SizedBox(height: 8),
            const Text('Vui lòng nhập các chỉ số sức khỏe của bạn để hệ thống theo dõi.', style: TextStyle(fontSize: 16, color: AppTheme.secondaryTextColor)),
            const SizedBox(height: 24),

            // Bluetooth Connection Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BleDeviceScanScreen()),
                ),
                icon: const Icon(Icons.bluetooth),
                label: const Text('Kết nối thiết bị đo (Bluetooth)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Manrope')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('HOẶC NHẬP TAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedTextColor, letterSpacing: 1.2)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            
            // Huyết áp
            _buildBentoCard(
              icon: Icons.favorite,
              iconColor: AppTheme.primaryColor,
              title: 'Huyết áp',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TÂM THU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryTextColor, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _systolicController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Manrope'),
                          decoration: InputDecoration(
                            hintText: '120',
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.mutedTextColor)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TÂM TRƯƠNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryTextColor, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _diastolicController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Manrope'),
                          decoration: InputDecoration(
                            hintText: '80',
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
                    child: Text('mmHg', style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Nhịp tim
            _buildBentoCard(
              icon: Icons.monitor_heart,
              iconColor: AppTheme.warningColor,
              title: 'Nhịp tim',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NHỊP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryTextColor, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _heartRateController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Manrope'),
                          decoration: InputDecoration(
                            hintText: '72',
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
                    child: Text('bpm', style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // SpO2
            _buildBentoCard(
              icon: Icons.air,
              iconColor: AppTheme.accentColor,
              title: 'Nồng độ oxy trong máu (SpO2)',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CHỈ SỐ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryTextColor, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _spO2Controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Manrope'),
                          decoration: InputDecoration(
                            hintText: '98',
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
                    child: Text('%', style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor)),
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
                  backgroundColor: AppTheme.primaryColor,
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
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
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
