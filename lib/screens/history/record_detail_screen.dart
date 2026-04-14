import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/health_record.dart';
import '../../config/health_constants.dart';

class RecordDetailScreen extends StatelessWidget {
  final HealthRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bản ghi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const Text(
              'Các chỉ số:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...record.indicators.entries.map((entry) => _buildIndicatorTile(entry.key, entry.value)),
            if (record.note != null && record.note!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Ghi chú:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(record.note!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _getTypeColor(record.type),
              child: Icon(_getTypeIcon(record.type), color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeName(record.type),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorTile(String key, double value) {
    final config = _getIndicatorConfig(key);
    final name = config['name'] ?? key;
    final unit = config['unit'] ?? '';
    final min = config['min'];
    final max = config['max'];

    Color statusColor = Colors.green;
    String statusText = 'Bình thường';

    if (min != null && value < min) {
      statusColor = Colors.orange;
      statusText = 'Thấp';
    } else if (max != null && value > max) {
      statusColor = Colors.red;
      statusText = 'Cao';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(name),
        subtitle: min != null && max != null ? Text('Khoảng chuẩn: $min - $max $unit') : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$value $unit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
            ),
            Text(
              statusText,
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
          ],
        ),
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
      case RecordType.bloodTest: return Colors.red;
      case RecordType.vitals: return Colors.pink;
      case RecordType.bodyMetrics: return Colors.blue;
    }
  }

  IconData _getTypeIcon(RecordType type) {
    switch (type) {
      case RecordType.bloodTest: return Icons.bloodtype;
      case RecordType.vitals: return Icons.favorite;
      case RecordType.bodyMetrics: return Icons.monitor_weight;
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
