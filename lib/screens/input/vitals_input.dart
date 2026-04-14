import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/health_constants.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/indicator_field.dart';

class VitalsInput extends StatefulWidget {
  const VitalsInput({super.key});

  @override
  State<VitalsInput> createState() => _VitalsInputState();
}

class _VitalsInputState extends State<VitalsInput> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    HealthConstants.vitalsIndicators.forEach((key, value) {
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
      appBar: AppBar(title: const Text('Nhập chỉ số sinh tồn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...HealthConstants.vitalsIndicators.entries.map((entry) {
              final config = entry.value;
              return IndicatorField(
                label: config['name'],
                unit: config['unit'],
                min: config['min'],
                max: config['max'],
                controller: _controllers[entry.key]!,
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Lưu chỉ số'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
