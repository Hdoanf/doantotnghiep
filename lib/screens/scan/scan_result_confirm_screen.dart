import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../widgets/indicator_field.dart';
import '../../config/health_constants.dart';
import '../../services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ScanResultConfirmScreen extends StatefulWidget {
  final Map<String, double> initialIndicators;
  final RecordType type;

  const ScanResultConfirmScreen({
    super.key,
    required this.initialIndicators,
    required this.type,
  });

  @override
  State<ScanResultConfirmScreen> createState() =>
      _ScanResultConfirmScreenState();
}

class _ScanResultConfirmScreenState extends State<ScanResultConfirmScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = HealthConstants.scanIndicators;
    config.forEach((key, value) {
      _controllers[key] = TextEditingController(
        text: widget.initialIndicators.containsKey(key)
            ? widget.initialIndicators[key]!.toString()
            : '',
      );
    });
  }

  List<MapEntry<String, dynamic>> _scanConfigEntries() {
    final detected = <MapEntry<String, dynamic>>[];
    final empty = <MapEntry<String, dynamic>>[];

    for (final entry in HealthConstants.scanIndicators.entries) {
      if (widget.initialIndicators.containsKey(entry.key)) {
        detected.add(entry);
      } else {
        empty.add(entry);
      }
    }

    return [...detected, ...empty];
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
        type: widget.type,
        indicators: indicators,
      );
      await FirestoreService().addHealthRecord(record);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu dữ liệu thành công')),
        );
      }
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
    final configEntries = _scanConfigEntries();
    final detectedCount = widget.initialIndicators.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận thông tin quét')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.infoLightColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.infoColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.infoColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI đã nhận diện $detectedCount chỉ số',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Kiểm tra lại và chỉnh sửa nếu cần thiết',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...configEntries.map((entry) {
              final key = entry.key;
              final item = entry.value;
              return IndicatorField(
                label: item['name'],
                unit: item['unit'],
                min: item['min'],
                max: item['max'],
                controller: _controllers[key]!,
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
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Xác nhận & Lưu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
