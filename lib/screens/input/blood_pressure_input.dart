import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/indicator_field.dart';

class BloodPressureInput extends StatefulWidget {
  const BloodPressureInput({super.key});

  @override
  State<BloodPressureInput> createState() => _BloodPressureInputState();
}

class _BloodPressureInputState extends State<BloodPressureInput> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final indicators = <String, double>{};
    final systolic = double.tryParse(_systolicController.text.trim());
    final diastolic = double.tryParse(_diastolicController.text.trim());
    final heartRate = double.tryParse(_heartRateController.text.trim());

    if (systolic != null) indicators['systolic'] = systolic;
    if (diastolic != null) indicators['diastolic'] = diastolic;
    if (heartRate != null) indicators['heart_rate'] = heartRate;

    if (indicators.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập ít nhất một chỉ số huyết áp')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirestoreService().addHealthRecord(
        HealthRecord(
          id: '',
          userId: user.uid,
          date: DateTime.now(),
          type: RecordType.vitals,
          indicators: indicators,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập huyết áp')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.criticalColor.withValues(alpha: 0.08),
                    AppTheme.warningColor.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.criticalColor.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.criticalColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppTheme.criticalColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Huyết áp & Nhịp tim', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textColor)),
                        SizedBox(height: 2),
                        Text('Đo sau khi nghỉ ngơi 5 phút để có kết quả chính xác', style: TextStyle(fontSize: 12, color: AppTheme.secondaryTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            IndicatorField(
              label: 'Huyết áp tâm thu',
              unit: 'mmHg',
              min: 90,
              max: 120,
              controller: _systolicController,
            ),
            IndicatorField(
              label: 'Huyết áp tâm trương',
              unit: 'mmHg',
              min: 60,
              max: 80,
              controller: _diastolicController,
            ),
            IndicatorField(
              label: 'Nhịp tim',
              unit: 'bpm',
              min: 60,
              max: 100,
              controller: _heartRateController,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ví dụ: đo sau khi nghỉ 5 phút',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Lưu huyết áp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
