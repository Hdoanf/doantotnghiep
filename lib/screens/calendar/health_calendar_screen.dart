import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../input/blood_pressure_input.dart';

class HealthCalendarScreen extends StatefulWidget {
  const HealthCalendarScreen({super.key});

  @override
  State<HealthCalendarScreen> createState() => _HealthCalendarScreenState();
}

class _HealthCalendarScreenState extends State<HealthCalendarScreen> {
  final _firestoreService = FirestoreService();
  Stream<List<HealthRecord>>? _recordsStream;
  String? _recordsUserId;

  Stream<List<HealthRecord>> _streamForUser(String userId) {
    if (_recordsUserId != userId) {
      _recordsUserId = userId;
      _recordsStream = _firestoreService.getHealthRecords(userId);
    }
    return _recordsStream!;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Lịch sức khỏe',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<List<HealthRecord>>(
        stream: _streamForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Không tải được dữ liệu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Manrope'),
                ),
              ),
            );
          }

          final records = snapshot.data ?? [];
          final grouped = _groupByDay(records);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _todayCard(context, records),
              const SizedBox(height: 32),
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              if (grouped.isEmpty)
                _emptyState()
              else
                ...grouped.entries.map((entry) {
                  return _dayGroup(entry.key, entry.value);
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _todayCard(BuildContext context, List<HealthRecord> records) {
    final todayCount = records.where((record) {
      final now = DateTime.now();
      return record.date.year == now.year &&
          record.date.month == now.month &&
          record.date.day == now.day;
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d/M/yyyy', 'vi').format(DateTime.now()),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$todayCount bản ghi trong hôm nay',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BloodPressureInput()),
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primaryColor,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentLightColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppTheme.primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có hoạt động sức khỏe',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                color: AppTheme.mutedTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayGroup(DateTime day, List<HealthRecord> records) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(day),
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppTheme.secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...records.map(_recordTile),
        ],
      ),
    );
  }

  Widget _recordTile(HealthRecord record) {
    final typeColor = _typeColor(record);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(record), color: typeColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(record),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(record.date),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppTheme.mutedTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (record.indicators.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${record.indicators.length} chỉ số',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: typeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<DateTime, List<HealthRecord>> _groupByDay(List<HealthRecord> records) {
    final grouped = <DateTime, List<HealthRecord>>{};
    for (final record in records) {
      final day = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      grouped.putIfAbsent(day, () => []).add(record);
    }
    return grouped;
  }

  Color _typeColor(HealthRecord record) {
    if (record.indicators.isEmpty && record.note != null) {
      return AppTheme.primaryColor;
    }
    return switch (record.type) {
      RecordType.bloodTest => Colors.redAccent,
      RecordType.vitals => Colors.orangeAccent,
      RecordType.bodyMetrics => AppTheme.primaryColor,
    };
  }

  IconData _typeIcon(HealthRecord record) {
    if (record.indicators.isEmpty && record.note != null) {
      return Icons.edit_note_rounded;
    }
    return switch (record.type) {
      RecordType.bloodTest => Icons.bloodtype_rounded,
      RecordType.vitals => Icons.monitor_heart_rounded,
      RecordType.bodyMetrics => Icons.monitor_weight_rounded,
    };
  }

  String _typeLabel(HealthRecord record) {
    if (record.indicators.isEmpty && record.note != null) {
      return 'Nhật ký sức khỏe';
    }
    return switch (record.type) {
      RecordType.bloodTest => 'Xét nghiệm máu',
      RecordType.vitals => 'Chỉ số sinh tồn',
      RecordType.bodyMetrics => 'Chỉ số cơ thể',
    };
  }
}
