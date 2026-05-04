import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../config/health_constants.dart';

class RecordDetailScreen extends StatelessWidget {
  final HealthRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bản ghi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const Text(
              'Các chỉ số',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 14),
            ...record.indicators.entries.map(
              (entry) => _buildIndicatorTile(entry.key, entry.value),
            ),
            if (record.note != null && record.note!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface2Color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  record.note!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final typeColor = _getTypeColor(record.type);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            typeColor.withValues(alpha: 0.08),
            typeColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getTypeIcon(record.type),
              color: typeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeName(record.type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppTheme.mutedTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                      style: const TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${record.indicators.length}',
              style: TextStyle(
                color: typeColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorTile(String key, double value) {
    final config = _getIndicatorConfig(key);
    final name = config['name'] ?? key;
    final unit = config['unit'] ?? '';
    final min = config['min'];
    final max = config['max'];

    Color statusColor = AppTheme.normalColor;
    String statusText = 'Bình thường';
    IconData statusIcon = Icons.check_circle_outline_rounded;

    if (min != null && value < min) {
      statusColor = AppTheme.warningColor;
      statusText = 'Thấp';
      statusIcon = Icons.arrow_downward_rounded;
    } else if (max != null && value > max) {
      statusColor = AppTheme.criticalColor;
      statusText = 'Cao';
      statusIcon = Icons.arrow_upward_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textColor,
                  ),
                ),
                if (min != null && max != null)
                  Text(
                    'Khoảng chuẩn: $min – $max $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedTextColor,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value $unit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 13, color: statusColor),
                  const SizedBox(width: 3),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getIndicatorConfig(String key) {
    if (HealthConstants.bloodIndicators.containsKey(key)) return HealthConstants.bloodIndicators[key];
    if (HealthConstants.vitalsIndicators.containsKey(key)) return HealthConstants.vitalsIndicators[key];
    if (HealthConstants.bodyIndicators.containsKey(key)) return HealthConstants.bodyIndicators[key];
    return {};
  }

  Color _getTypeColor(RecordType type) {
    switch (type) {
      case RecordType.bloodTest: return AppTheme.criticalColor;
      case RecordType.vitals: return AppTheme.warningColor;
      case RecordType.bodyMetrics: return AppTheme.infoColor;
    }
  }

  IconData _getTypeIcon(RecordType type) {
    switch (type) {
      case RecordType.bloodTest: return Icons.bloodtype_rounded;
      case RecordType.vitals: return Icons.monitor_heart_rounded;
      case RecordType.bodyMetrics: return Icons.monitor_weight_rounded;
    }
  }

  String _getTypeName(RecordType type) {
    switch (type) {
      case RecordType.bloodTest: return 'Xét nghiệm máu';
      case RecordType.vitals: return 'Chỉ số sinh tồn';
      case RecordType.bodyMetrics: return 'Chỉ số cơ thể';
    }
  }
}
