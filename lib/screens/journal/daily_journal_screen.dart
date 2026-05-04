import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final _noteController = TextEditingController();
  String _mood = 'Bình thường';
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập nội dung nhật ký trước khi lưu')),
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
          indicators: const {},
          note: 'Tâm trạng: $_mood\n$note',
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
      appBar: AppBar(title: const Text('Nhật ký hôm nay')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tâm trạng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Tốt',
                'Bình thường',
                'Mệt',
                'Đau',
                'Căng thẳng',
              ].map(_moodChip).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              minLines: 8,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Ghi chú sức khỏe',
                hintText: 'Triệu chứng, thuốc đã uống, ăn uống, vận động...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu nhật ký'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moodChip(String mood) {
    final selected = _mood == mood;
    return ChoiceChip(
      label: Text(mood),
      selected: selected,
      onSelected: (_) => setState(() => _mood = mood),
      selectedColor: AppTheme.accentLightColor,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
      ),
    );
  }
}
