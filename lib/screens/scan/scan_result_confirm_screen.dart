import 'package:flutter/material.dart';
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
  State<ScanResultConfirmScreen> createState() => _ScanResultConfirmScreenState();
}

class _ScanResultConfirmScreenState extends State<ScanResultConfirmScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = _getIndicatorConfigForType(widget.type);
    config.forEach((key, value) {
      _controllers[key] = TextEditingController(
        text: widget.initialIndicators.containsKey(key)
            ? widget.initialIndicators[key]!.toString()
            : '',
      );
    });
  }

  Map<String, dynamic> _getIndicatorConfigForType(RecordType type) {
    switch (type) {
      case RecordType.bloodTest: return HealthConstants.bloodIndicators;
      case RecordType.vitals: return HealthConstants.vitalsIndicators;
      case RecordType.bodyMetrics: return HealthConstants.bodyIndicators;
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getIndicatorConfigForType(widget.type);

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận thông tin quét')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Vui lòng kiểm tra lại các chỉ số AI đã trích xuất được. Bạn có thể chỉnh sửa nếu cần thiết.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ...config.entries.map((entry) {
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác nhận & Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
