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
      appBar: AppBar(title: const Text('Lịch sức khỏe')),
      body: StreamBuilder<List<HealthRecord>>(
        stream: _streamForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Không tải được dữ liệu Firestore.\n${snapshot.error}',
                  textAlign: TextAlign.center,
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
              const SizedBox(height: 24),
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d/M/yyyy', 'vi').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$todayCount bản ghi trong hôm nay',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentLightColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có hoạt động sức khỏe',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayGroup(DateTime day, List<HealthRecord> records) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surface2Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(day),
              style: const TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...records.map(_recordTile),
        ],
      ),
    );
  }

  Widget _recordTile(HealthRecord record) {
    final typeColor = _typeColor(record);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(record), color: typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(record),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(record.date),
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (record.indicators.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${record.indicators.length} chỉ số',
                style: TextStyle(
                  color: typeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
      return AppTheme.normalColor;
    }
    return switch (record.type) {
      RecordType.bloodTest => AppTheme.criticalColor,
      RecordType.vitals => AppTheme.warningColor,
      RecordType.bodyMetrics => AppTheme.infoColor,
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
