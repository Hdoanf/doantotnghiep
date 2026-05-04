import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/health_constants.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/indicator_field.dart';

class BodyMetricsInput extends StatefulWidget {
  const BodyMetricsInput({super.key});

  @override
  State<BodyMetricsInput> createState() => _BodyMetricsInputState();
}

class _BodyMetricsInputState extends State<BodyMetricsInput> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    HealthConstants.bodyIndicators.forEach((key, value) {
      _controllers[key] = TextEditingController();
    });
  }

  void _save() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final indicators = <String, double>{};
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        final val = double.tryParse(controller.text);
        if (val != null) indicators[key] = val;
      }
    });

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
      appBar: AppBar(title: const Text('Nhập chỉ số cơ thể')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.infoLightColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monitor_weight_rounded, color: AppTheme.infoColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chỉ số cơ thể', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textColor)),
                        Text('Cân nặng, chiều cao', style: TextStyle(fontSize: 12, color: AppTheme.secondaryTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...HealthConstants.bodyIndicators.entries.map((entry) {
              final config = entry.value;
              return IndicatorField(
                label: config['name'],
                unit: config['unit'],
                min: config['min'],
                max: config['max'],
                controller: _controllers[entry.key]!,
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Lưu chỉ số'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white,
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
