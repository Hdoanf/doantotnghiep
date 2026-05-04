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

  static const _moods = [
    {'label': 'Tốt', 'emoji': '😊', 'hex': 0xFF10B981},
    {'label': 'Bình thường', 'emoji': '😐', 'hex': 0xFF3B82F6},
    {'label': 'Mệt', 'emoji': '😴', 'hex': 0xFFF59E0B},
    {'label': 'Đau', 'emoji': '😣', 'hex': 0xFFEF4444},
    {'label': 'Căng thẳng', 'emoji': '😤', 'hex': 0xFF8B5CF6},
  ];

  @override
  void dispose() { _noteController.dispose(); super.dispose(); }

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
      await FirestoreService().addHealthRecord(HealthRecord(
        id: '', userId: user.uid, date: DateTime.now(),
        type: RecordType.vitals, indicators: const {},
        note: 'Tâm trạng: $_mood\n$note',
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _moodSection(),
          const SizedBox(height: 20),
          _noteSection(),
          const SizedBox(height: 28),
          _saveBtn(),
        ]),
      ),
    );
  }

  Widget _moodSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Bạn cảm thấy thế nào?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _moods.map(_moodBtn).toList()),
      ]),
    );
  }

  Widget _moodBtn(Map<String, dynamic> m) {
    final label = m['label'] as String;
    final emoji = m['emoji'] as String;
    final color = Color(m['hex'] as int);
    final sel = _mood == label;
    return GestureDetector(
      onTap: () => setState(() => _mood = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), width: 56,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? color.withValues(alpha: 0.4) : AppTheme.borderColor.withValues(alpha: 0.3), width: sel ? 1.5 : 1),
        ),
        child: Column(children: [
          Text(emoji, style: TextStyle(fontSize: sel ? 26 : 22)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: sel ? color : AppTheme.mutedTextColor)),
        ]),
      ),
    );
  }

  Widget _noteSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ghi chú sức khỏe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController, minLines: 6, maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Triệu chứng, thuốc đã uống, ăn uống, vận động...',
            filled: true, fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.4))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.4))),
          ),
        ),
      ]),
    );
  }

  Widget _saveBtn() {
    return SizedBox(width: double.infinity, height: 54, child: DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined),
        label: Text(_isSaving ? 'Đang lưu...' : 'Lưu nhật ký'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    ));
  }
}
