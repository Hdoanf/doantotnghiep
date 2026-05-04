import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HealthMetricsScreen extends StatefulWidget {
  const HealthMetricsScreen({super.key});

  @override
  State<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends State<HealthMetricsScreen> {
  final _firestoreService = FirestoreService();
  Stream<List<HealthRecord>>? _recordsStream;
  String? _recordsUserId;

  Stream<List<HealthRecord>> _streamForUser(String userId) {
    if (_recordsUserId != userId) {
      _recordsUserId = userId;
      _recordsStream = _firestoreService.getRecentHealthRecords(userId);
    }
    return _recordsStream!;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉ số sức khỏe')),
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
          if (records.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu chỉ số'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _metricsGrid(records),
                const SizedBox(height: 24),
                _bloodPressureChart(records),
                const SizedBox(height: 16),
                _healthInsight(records),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricsGrid(List<HealthRecord> records) {
    final metrics = _metricsFrom(records);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.52,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: metrics.map(_metricTile).toList(),
    );
  }

  Widget _metricTile(_MetricSummary metric) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 18, color: metric.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                metric.value,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                metric.unit,
                style: const TextStyle(
                  color: AppTheme.mutedTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          _statusBadge(metric.status, metric.color),
        ],
      ),
    );
  }

  Widget _bloodPressureChart(List<HealthRecord> records) {
    final chartRecords = records
        .where((r) => r.indicators['systolic'] != null)
        .take(7)
        .toList()
        .reversed
        .toList();

    if (chartRecords.isEmpty) {
      return Container(
        height: 200,
        decoration: _surfaceDecoration(),
        child: const Center(child: Text('Chưa có dữ liệu xu hướng huyết áp')),
      );
    }

    final values = chartRecords
        .map((record) => record.indicators['systolic']!)
        .toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xu hướng huyết áp (7 ngày)',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: (minValue - 12).clamp(0, double.infinity).toDouble(),
                maxY: maxValue + 12,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.borderColor.withValues(alpha: 0.22),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      chartRecords.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        chartRecords[i].indicators['systolic']!,
                      ),
                    ),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthInsight(List<HealthRecord> records) {
    final latest = records.isNotEmpty ? records.first.indicators : null;
    final systolic = latest?['systolic'];
    final diastolic = latest?['diastolic'];
    final isHigh =
        (systolic != null && systolic > 120) ||
        (diastolic != null && diastolic > 80);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isHigh
                  ? 'Huyết áp đang cao hơn ngưỡng bình thường. Nên theo dõi đều và nghỉ ngơi hợp lý.'
                  : 'Huyết áp ổn định trong khoảng bình thường. Tiếp tục duy trì chế độ sinh hoạt hiện tại.',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_MetricSummary> _metricsFrom(List<HealthRecord> records) {
    double? systolic, diastolic, heartRate, glucose, weight, height;

    for (var record in records) {
      systolic ??= record.indicators['systolic'];
      diastolic ??= record.indicators['diastolic'];
      heartRate ??= record.indicators['heart_rate'];
      glucose ??= record.indicators['glucose'];
      weight ??= record.indicators['weight'];
      height ??= record.indicators['height'];
    }

    final bmi = weight != null && height != null && height > 0
        ? weight / ((height / 100) * (height / 100))
        : null;

    return [
      _MetricSummary(
        label: 'Huyết áp',
        value: systolic != null && diastolic != null
            ? '${systolic.toInt()}/${diastolic.toInt()}'
            : '--',
        unit: 'mmHg',
        icon: Icons.favorite,
        status: _bloodPressureStatus(systolic: systolic, diastolic: diastolic),
      ),
      _MetricSummary(
        label: 'Đường huyết',
        value: glucose?.toStringAsFixed(1) ?? '--',
        unit: 'mmol/L',
        icon: Icons.water_drop,
        status: _statusFor(glucose, min: 3.9, max: 6.4),
      ),
      _MetricSummary(
        label: 'Nhịp tim',
        value: heartRate?.toInt().toString() ?? '--',
        unit: 'bpm',
        icon: Icons.monitor_heart,
        status: _statusFor(heartRate, min: 60, max: 100),
      ),
      _MetricSummary(
        label: 'Cân nặng',
        value: weight?.toInt().toString() ?? '--',
        unit: 'kg',
        icon: Icons.square_rounded,
        status: _statusFor(weight, min: 40, max: 100),
      ),
      if (bmi != null)
        _MetricSummary(
          label: 'BMI',
          value: bmi.toStringAsFixed(1),
          unit: '',
          icon: Icons.speed,
          status: _statusFor(bmi, min: 18.5, max: 24.9),
        ),
    ];
  }

  BoxDecoration _surfaceDecoration() {
    return BoxDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _statusFor(double? value, {required double min, required double max}) {
    if (value == null) return 'Chưa có dữ liệu';
    if (value < min) return 'Thấp';
    if (value > max) return 'Cao';
    return 'Bình thường';
  }

  String _bloodPressureStatus({double? systolic, double? diastolic}) {
    if (systolic == null || diastolic == null) return 'Chưa có dữ liệu';
    if (systolic > 120 || diastolic > 80) return 'Cao';
    if (systolic < 90 || diastolic < 60) return 'Thấp';
    return 'Bình thường';
  }
}

class _MetricSummary {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String status;

  const _MetricSummary({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
  });

  Color get color {
    return switch (status) {
      'Cao' => AppTheme.warningColor,
      'Thấp' => AppTheme.infoColor,
      'Chưa có dữ liệu' => AppTheme.mutedTextColor,
      _ => AppTheme.primaryColor,
    };
  }
}
