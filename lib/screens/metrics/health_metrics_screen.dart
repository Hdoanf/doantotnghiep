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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chỉ số sức khỏe',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<HealthRecord>>(
        stream: _streamForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(fontFamily: 'Manrope')));
          final records = snapshot.data ?? [];
          if (records.isEmpty) return _empty();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _metricsGrid(records),
              const SizedBox(height: 24),
              _bpChart(records),
              const SizedBox(height: 20),
              _insight(records),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentLightColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryColor, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có dữ liệu chỉ số',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy bắt đầu nhập dữ liệu sức khỏe của bạn.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(List<HealthRecord> records) {
    final metrics = _metricsFrom(records);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: metrics.map(_metricTile).toList(),
    );
  }

  Widget _metricTile(_MetricSummary m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: m.color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: m.color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: m.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(m.icon, size: 16, color: m.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppTheme.secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(
            m.value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: AppTheme.textColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            m.unit,
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: AppTheme.mutedTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: m.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_statusIcon(m.status), size: 12, color: m.color),
            const SizedBox(width: 4),
            Text(
              m.status,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: m.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  IconData _statusIcon(String s) {
    if (s == 'Cao') return Icons.arrow_upward_rounded;
    if (s == 'Thấp') return Icons.arrow_downward_rounded;
    if (s == 'Bình thường') return Icons.check_circle_outline_rounded;
    return Icons.remove;
  }

  Widget _bpChart(List<HealthRecord> records) {
    final cr = records.where((r) => r.indicators['systolic'] != null).take(7).toList().reversed.toList();
    if (cr.isEmpty) {
      return Container(
        height: 180,
        decoration: _surfDeco(),
        child: const Center(
          child: Text(
            'Chưa có dữ liệu xu hướng huyết áp',
            style: TextStyle(fontFamily: 'Manrope', color: AppTheme.secondaryTextColor),
          ),
        ),
      );
    }
    final vals = cr.map((r) => r.indicators['systolic']!).toList();
    final mn = vals.reduce((a, b) => a < b ? a : b), mx = vals.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.criticalColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded, color: AppTheme.criticalColor, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'Xu hướng huyết áp (7 ngày)',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: (mn - 10).clamp(0, double.infinity).toDouble(),
              maxY: mx + 10,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppTheme.borderColor.withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(cr.length, (i) => FlSpot(i.toDouble(), cr[i].indicators['systolic']!)),
                  isCurved: true,
                  color: AppTheme.criticalColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (a, b, c, d) => FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.criticalColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.criticalColor.withValues(alpha: 0.1),
                  ),
                )
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _insight(List<HealthRecord> records) {
    final latest = records.isNotEmpty ? records.first.indicators : null;
    final sys = latest?['systolic'], dia = latest?['diastolic'];
    final isHigh = (sys != null && sys > 120) || (dia != null && dia > 80);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isHigh ? AppTheme.warningColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
            isHigh ? AppTheme.warningColor.withValues(alpha: 0.02) : AppTheme.primaryColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHigh ? AppTheme.warningColor.withValues(alpha: 0.2) : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isHigh ? AppTheme.warningColor.withValues(alpha: 0.15) : AppTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.medical_services_outlined,
            size: 22,
            color: isHigh ? AppTheme.warningColor : AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            isHigh
                ? 'Huyết áp đang cao hơn ngưỡng bình thường. Nên theo dõi đều và nghỉ ngơi hợp lý.'
                : 'Huyết áp ổn định trong khoảng bình thường. Tiếp tục duy trì chế độ sinh hoạt hiện tại.',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: isHigh ? AppTheme.warningColor : AppTheme.primaryColor,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }

  List<_MetricSummary> _metricsFrom(List<HealthRecord> records) {
    double? sys, dia, hr, glu, w, h;
    for (var r in records) {
      sys ??= r.indicators['systolic'];
      dia ??= r.indicators['diastolic'];
      hr ??= r.indicators['heart_rate'];
      glu ??= r.indicators['glucose'];
      w ??= r.indicators['weight'];
      h ??= r.indicators['height'];
    }
    final bmi = w != null && h != null && h > 0 ? w / ((h / 100) * (h / 100)) : null;
    return [
      _MetricSummary(
        label: 'Huyết áp',
        value: sys != null && dia != null ? '${sys.toInt()}/${dia.toInt()}' : '--',
        unit: 'mmHg',
        icon: Icons.favorite_rounded,
        status: _bpStatus(systolic: sys, diastolic: dia),
      ),
      _MetricSummary(
        label: 'Đường huyết',
        value: glu?.toStringAsFixed(1) ?? '--',
        unit: 'mmol/L',
        icon: Icons.water_drop_rounded,
        status: _statusFor(glu, min: 3.9, max: 6.4),
      ),
      _MetricSummary(
        label: 'Nhịp tim',
        value: hr?.toInt().toString() ?? '--',
        unit: 'bpm',
        icon: Icons.monitor_heart_rounded,
        status: _statusFor(hr, min: 60, max: 100),
      ),
      _MetricSummary(
        label: 'Cân nặng',
        value: w?.toInt().toString() ?? '--',
        unit: 'kg',
        icon: Icons.monitor_weight_rounded,
        status: _statusFor(w, min: 40, max: 100),
      ),
      if (bmi != null)
        _MetricSummary(
          label: 'BMI',
          value: bmi.toStringAsFixed(1),
          unit: '',
          icon: Icons.speed_rounded,
          status: _statusFor(bmi, min: 18.5, max: 24.9),
        ),
    ];
  }

  BoxDecoration _surfDeco() => BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
      );

  String _statusFor(double? v, {required double min, required double max}) {
    if (v == null) return 'Chưa có';
    if (v < min) return 'Thấp';
    if (v > max) return 'Cao';
    return 'Bình thường';
  }

  String _bpStatus({double? systolic, double? diastolic}) {
    if (systolic == null || diastolic == null) return 'Chưa có';
    if (systolic > 120 || diastolic > 80) return 'Cao';
    if (systolic < 90 || diastolic < 60) return 'Thấp';
    return 'Bình thường';
  }
}

class _MetricSummary {
  final String label, value, unit, status;
  final IconData icon;
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
      'Chưa có' => AppTheme.mutedTextColor,
      _ => AppTheme.primaryColor
    };
  }
}
