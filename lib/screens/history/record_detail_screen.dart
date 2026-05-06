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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chi tiết bản ghi',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            const Text(
              'Các chỉ số chi tiết',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...record.indicators.entries.map(
              (entry) => _buildIndicatorTile(entry.key, entry.value),
            ),
            if (record.note != null && record.note!.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Ghi chú',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  record.note!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: AppTheme.secondaryTextColor,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final typeColor = _getTypeColor(record.type);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getTypeIcon(record.type),
              color: typeColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeName(record.type),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: AppTheme.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${record.indicators.length}',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: typeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Chỉ số',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

    Color statusColor = AppTheme.primaryColor;
    String statusText = 'Bình thường';
    IconData statusIcon = Icons.check_circle;

    if (min != null && value < min) {
      statusColor = Colors.orangeAccent;
      statusText = 'Thấp';
      statusIcon = Icons.arrow_downward_rounded;
    } else if (max != null && value > max) {
      statusColor = Colors.redAccent;
      statusText = 'Cao';
      statusIcon = Icons.arrow_upward_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (min != null && max != null)
                  Text(
                    'Chuẩn: $min – $max $unit',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
      case RecordType.bloodTest: return Colors.redAccent;
      case RecordType.vitals: return Colors.orangeAccent;
      case RecordType.bodyMetrics: return AppTheme.primaryColor;
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
