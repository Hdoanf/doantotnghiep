import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../models/health_record.dart';
import '../calendar/health_calendar_screen.dart';
import '../input/blood_test_input.dart';
import '../input/blood_pressure_input.dart';
import '../input/body_metrics_input.dart';
import '../journal/daily_journal_screen.dart';
import '../metrics/health_metrics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, userName: _displayName(user)),
                  const SizedBox(height: 28),
                  _buildQuickActions(context),
                  const SizedBox(height: 30),
                  _buildAIReportButton(context, records),
                  const SizedBox(height: 32),
                  _sectionHeader(
                    title: 'Chỉ số gần đây',
                    actionLabel: 'Chi tiết',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HealthMetricsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCards(records),
                  const SizedBox(height: 16),
                  _buildChart(records),
                  const SizedBox(height: 16),
                  _buildHealthInsight(records),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _displayName(dynamic user) {
    final displayName = user.displayName;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return user.email.split('@')[0];
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day}/${now.month}/${now.year}';
  }

  Widget _buildTopBar(BuildContext context, {required String userName}) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'H';

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.backgroundColor, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, $userName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _todayLabel(),
                style: const TextStyle(
                  color: AppTheme.mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        _topIconButton(
          icon: Icons.notifications_none_rounded,
          label: 'Thông báo',
          badgeCount: 3,
          onPressed: () {},
        ),
        const SizedBox(width: 6),
        _topIconButton(
          icon: Icons.search_rounded,
          label: 'Tìm kiếm',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _topIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    int? badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, color: AppTheme.textColor, size: 24),
        ),
        if (badgeCount != null)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppTheme.criticalColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAIReportButton(
    BuildContext context,
    List<HealthRecord> records,
  ) {
    return GestureDetector(
      onTap: () => _showAIReport(context, records),
      child: Container(
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo báo cáo sức khỏe AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Phân tích tổng quát các chỉ số gần đây',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  void _showAIReport(BuildContext context, List<HealthRecord> records) async {
    final gemini = GeminiService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final report = await gemini.generateSummaryReport(records);
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _aiReportSheet(context, report),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyAiError(e))));
      }
    }
  }

  String _friendlyAiError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('429') || message.contains('quota')) {
      return 'AI đang hết quota tạm thời. Chờ một lúc rồi thử lại.';
    }
    return 'Lỗi AI: $message';
  }

  Widget _aiReportSheet(BuildContext context, String report) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.accentLightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Báo cáo phân tích AI',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tóm tắt từ các chỉ số gần đây',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _formattedAiReport(report),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formattedAiReport(String report) {
    final lines = report
        .split('\n')
        .map((line) => line.trim().replaceFirst(RegExp(r'^[-*#\s]+'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final cleanLine = line.replaceAll('**', '');
          final isHeading =
              cleanLine.endsWith(':') ||
              ['Tổng quan', 'Điểm cần theo dõi', 'Gợi ý'].contains(cleanLine);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isHeading) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    cleanLine,
                    style: TextStyle(
                      color: isHeading
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryTextColor,
                      fontSize: isHeading ? 15 : 13,
                      height: 1.45,
                      fontWeight: isHeading ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(List<HealthRecord> records) {
    final chartRecords = records
        .where((r) => r.indicators['systolic'] != null)
        .take(7)
        .toList()
        .reversed
        .toList();

    if (chartRecords.isEmpty) {
      return Container(
        height: 200,
        decoration: _metricDecoration(),
        child: const Center(child: Text('Chưa có dữ liệu xu hướng huyết áp')),
      );
    }

    final values = chartRecords
        .map((record) => record.indicators['systolic']!)
        .toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minY = (minValue - 12).clamp(0, double.infinity).toDouble();
    final maxY = maxValue + 12;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _metricDecoration(),
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
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
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
                    spots: List.generate(chartRecords.length, (i) {
                      return FlSpot(
                        i.toDouble(),
                        chartRecords[i].indicators['systolic']!,
                      );
                    }),
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

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          _actionButton(
            context,
            Icons.camera_alt_rounded,
            'Chụp/Scan\nphiếu khám',
            AppTheme.primaryColor,
            const BloodTestInput(),
          ),
          _actionButton(
            context,
            Icons.favorite_rounded,
            'Huyết áp\nnhịp tim',
            AppTheme.criticalColor,
            const BloodPressureInput(),
          ),
          _actionButton(
            context,
            Icons.analytics_rounded,
            'Chỉ số\nsức khỏe',
            const Color(0xFF8B5CF6),
            const HealthMetricsScreen(),
          ),
          _actionButton(
            context,
            Icons.monitor_weight_rounded,
            'Cơ thể\ncân nặng',
            AppTheme.infoColor,
            const BodyMetricsInput(),
          ),
          _actionButton(
            context,
            Icons.edit_note_rounded,
            'Nhật ký\nhôm nay',
            AppTheme.normalColor,
            const DailyJournalScreen(),
          ),
          _actionButton(
            context,
            Icons.calendar_month_rounded,
            'Lịch\nkhám',
            AppTheme.warningColor,
            const HealthCalendarScreen(),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        width: 94,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<HealthRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu chỉ số'));
    }

    double? systolic, diastolic, heartRate, glucose, weight, height;

    for (var r in records) {
      systolic ??= r.indicators['systolic'];
      diastolic ??= r.indicators['diastolic'];
      heartRate ??= r.indicators['heart_rate'];
      glucose ??= r.indicators['glucose'];
      weight ??= r.indicators['weight'];
      height ??= r.indicators['height'];
    }

    final bmi = weight != null && height != null && height > 0
        ? weight / ((height / 100) * (height / 100))
        : null;
    final metrics = <_MetricSummary>[
      _MetricSummary(
        label: 'Huyết áp',
        value: systolic != null && diastolic != null
            ? '${systolic.toInt()}/${diastolic.toInt()}'
            : '--',
        unit: 'mmHg',
        icon: Icons.favorite,
        color: _statusColor(
          _bloodPressureStatus(systolic: systolic, diastolic: diastolic),
        ),
        status: _bloodPressureStatus(systolic: systolic, diastolic: diastolic),
      ),
      _MetricSummary(
        label: 'Đường huyết',
        value: glucose?.toStringAsFixed(1) ?? '--',
        unit: 'mmol/L',
        icon: Icons.water_drop,
        color: _statusColor(_statusFor(glucose, min: 3.9, max: 6.4)),
        status: _statusFor(glucose, min: 3.9, max: 6.4),
      ),
      _MetricSummary(
        label: 'Nhịp tim',
        value: heartRate?.toInt().toString() ?? '--',
        unit: 'bpm',
        icon: Icons.monitor_heart,
        color: _statusColor(_statusFor(heartRate, min: 60, max: 100)),
        status: _statusFor(heartRate, min: 60, max: 100),
      ),
      _MetricSummary(
        label: 'Cân nặng',
        value: weight?.toInt().toString() ?? '--',
        unit: 'kg',
        icon: Icons.square_rounded,
        color: _statusColor(_statusFor(weight, min: 40, max: 100)),
        status: _statusFor(weight, min: 40, max: 100),
      ),
      if (bmi != null)
        _MetricSummary(
          label: 'BMI',
          value: bmi.toStringAsFixed(1),
          unit: '',
          icon: Icons.speed,
          color: _statusColor(_statusFor(bmi, min: 18.5, max: 24.9)),
          status: _statusFor(bmi, min: 18.5, max: 24.9),
        ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.48,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: metrics.map(_summaryCard).toList(),
    );
  }

  Widget _summaryCard(_MetricSummary metric) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _metricDecoration(),
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

  BoxDecoration _metricDecoration() {
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

  Widget _buildHealthInsight(List<HealthRecord> records) {
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

  Color _statusColor(String status) {
    return switch (status) {
      'Cao' => AppTheme.warningColor,
      'Thấp' => AppTheme.infoColor,
      'Chưa có dữ liệu' => AppTheme.mutedTextColor,
      _ => AppTheme.primaryColor,
    };
  }
}

class _MetricSummary {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String status;

  const _MetricSummary({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
  });
}
