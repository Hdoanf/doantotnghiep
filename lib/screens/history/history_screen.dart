import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/health_record.dart';
import 'record_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    if (user == null) return const Center(child: Text('Vui lòng đăng nhập'));

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử sức khỏe')),
      body: StreamBuilder<List<HealthRecord>>(
        stream: _streamForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
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
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyState();
          }

          final records = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _recordCard(context, record);
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentLightColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy bắt đầu nhập chỉ số sức khỏe',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(BuildContext context, HealthRecord record) {
    final typeColor = _getTypeColor(record.type);
    final typeLight = typeColor.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: typeLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_getTypeIcon(record.type), color: typeColor, size: 22),
        ),
        title: Text(
          _getTypeName(record.type),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.textColor,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 13,
              color: AppTheme.mutedTextColor,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(record.date),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mutedTextColor,
              ),
            ),
            if (record.indicators.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentLightColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${record.indicators.length} chỉ số',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.mutedTextColor,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordDetailScreen(record: record),
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(RecordType type) {
    switch (type) {
      case RecordType.bloodTest:
        return AppTheme.criticalColor;
      case RecordType.vitals:
        return AppTheme.warningColor;
      case RecordType.bodyMetrics:
        return AppTheme.infoColor;
    }
  }

  IconData _getTypeIcon(RecordType type) {
    switch (type) {
      case RecordType.bloodTest:
        return Icons.bloodtype_rounded;
      case RecordType.vitals:
        return Icons.monitor_heart_rounded;
      case RecordType.bodyMetrics:
        return Icons.monitor_weight_rounded;
    }
  }

  String _getTypeName(RecordType type) {
    switch (type) {
      case RecordType.bloodTest:
        return 'Xét nghiệm máu';
      case RecordType.vitals:
        return 'Chỉ số sinh tồn';
      case RecordType.bodyMetrics:
        return 'Chỉ số cơ thể';
    }
  }
}
