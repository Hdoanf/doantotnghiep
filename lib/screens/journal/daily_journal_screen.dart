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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Nhật ký hôm nay',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _moodSection(),
          const SizedBox(height: 24),
          _noteSection(),
          const SizedBox(height: 32),
          _saveBtn(),
        ]),
      ),
    );
  }

  Widget _moodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Bạn cảm thấy thế nào?',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 20),
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
        duration: const Duration(milliseconds: 200),
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? color.withValues(alpha: 0.5) : AppTheme.borderColor.withValues(alpha: 0.3), width: sel ? 2 : 1),
        ),
        child: Column(children: [
          Text(emoji, style: TextStyle(fontSize: sel ? 28 : 24)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
              color: sel ? color : AppTheme.secondaryTextColor,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _noteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Ghi chú sức khỏe',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          minLines: 6,
          maxLines: 10,
          style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Nhập triệu chứng, loại thuốc đã uống, hoặc thông tin sức khỏe khác...',
            hintStyle: const TextStyle(color: AppTheme.mutedTextColor),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.4))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.4))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
          ),
        ),
      ]),
    );
  }

  Widget _saveBtn() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save_rounded),
        label: Text(
          _isSaving ? 'Đang lưu...' : 'Lưu nhật ký',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
