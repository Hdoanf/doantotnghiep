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
              const SizedBox(height: 16),
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (grouped.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('Chưa có hoạt động sức khỏe')),
                )
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentLightColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d/M/yyyy', 'vi').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$todayCount bản ghi trong hôm nay',
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Thêm huyết áp',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BloodPressureInput()),
            ),
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _dayGroup(DateTime day, List<HealthRecord> records) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy').format(day),
            style: const TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...records.map(_recordTile),
        ],
      ),
    );
  }

  Widget _recordTile(HealthRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(_typeIcon(record), color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(record),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
            Text(
              '${record.indicators.length} chỉ số',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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

  IconData _typeIcon(HealthRecord record) {
    if (record.indicators.isEmpty && record.note != null) {
      return Icons.edit_note;
    }
    return switch (record.type) {
      RecordType.bloodTest => Icons.bloodtype,
      RecordType.vitals => Icons.monitor_heart,
      RecordType.bodyMetrics => Icons.monitor_weight,
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
