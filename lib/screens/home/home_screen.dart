import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/ble_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../models/health_record.dart';
import '../input/blood_test_input.dart';
import '../input/vitals_input.dart';
import '../input/live_vitals_screen.dart';
import '../scan/ble_device_scan_screen.dart';
import '../input/body_metrics_input.dart';
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

  @override
  void initState() {
    super.initState();
    // Tự động kết nối lại với thiết bị cũ nếu có
    BleService().autoConnect();
  }

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
      appBar: _buildAppBar(user),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInputMenu(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
                ),
              ),
            );
          }
          final records = snapshot.data ?? [];
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingSection(_displayName(user)),
                  const SizedBox(height: 24),
                  _buildQuickAccessActions(context, records),
                  const SizedBox(height: 32),
                  _buildMetricsHeader(context),
                  const SizedBox(height: 12),
                  _buildBentoGrid(records),
                  const SizedBox(height: 24),
                  _buildChart(records),
                  const SizedBox(height: 24),
                  _buildHealthInsight(records),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic user) {
    final displayName = _displayName(user);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H';
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'HealthPulse VN',
        style: TextStyle(
          color: AppTheme.primaryLightColor,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryLightColor),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _displayName(dynamic user) {
    final displayName = user.displayName;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return user.email.split('@')[0];
  }

  Widget _buildGreetingSection(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chào buổi sáng,',
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dưới đây là tổng quan sức khỏe của bạn hôm nay. Mọi chỉ số đang trong tầm kiểm soát.',
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessActions(BuildContext context, List<HealthRecord> records) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BloodTestInput()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.document_scanner, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'QUÉT KẾT QUẢ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showAIReport(context, records),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.accentLightColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentLightColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.smart_toy, color: AppTheme.primaryColor, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'CHAT VỚI AI',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Chỉ số hôm nay',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manrope',
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthMetricsScreen()),
          ),
          child: const Text(
            'Xem tất cả',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(List<HealthRecord> records) {
    double? systolic, diastolic, glucose, cholesterol;

    for (var r in records) {
      systolic ??= r.indicators['systolic'];
      diastolic ??= r.indicators['diastolic'];
      glucose ??= r.indicators['glucose'];
      cholesterol ??= r.indicators['cholesterol'];
    }

    final bpStatus = _bloodPressureStatus(systolic: systolic, diastolic: diastolic);
    final glucoseStatus = _statusFor(glucose, min: 3.9, max: 6.4);
    final cholStatus = _statusFor(cholesterol, min: 0.0, max: 5.2);

    return Column(
      children: [
        // Heart Rate Live Card (New)
        StreamBuilder<Map<String, dynamic>>(
          stream: BleService().dataStream,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final bpm = data?['bpm'] ?? 0.0;
            final hasData = bpm > 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  if (BleService().connectedDevice != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveVitalsScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BleDeviceScanScreen()));
                  }
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nhịp tim trực tiếp',
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                hasData ? bpm.toStringAsFixed(0) : '--',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'BPM',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  ],
                ),
              ),
            );
          },
        ),
        // BP Card (span 2)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLightColor.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(bpStatus),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor(bpStatus).withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Huyết áp',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        systolic != null && diastolic != null
                            ? '${systolic.toInt()}/${diastolic.toInt()}'
                            : '--',
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'mmHg',
                        style: TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 32,
                    child: CustomPaint(
                      painter: _SparklinePainter(),
                      size: const Size(double.infinity, 32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Glucose
            Expanded(
              child: _buildSmallMetricCard(
                title: 'Đường huyết',
                value: glucose?.toStringAsFixed(1) ?? '--',
                unit: 'mmol/L',
                statusText: glucoseStatus,
                statusColor: _statusColor(glucoseStatus),
                iconData: Icons.water_drop_outlined,
              ),
            ),
            const SizedBox(width: 12),
            // Cholesterol
            Expanded(
              child: _buildSmallMetricCard(
                title: 'Cholesterol',
                value: cholesterol?.toStringAsFixed(1) ?? '--',
                unit: 'mmol/L',
                statusText: cholStatus,
                statusColor: _statusColor(cholStatus),
                iconData: Icons.science_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallMetricCard({
    required String title,
    required String value,
    required String unit,
    required String statusText,
    required Color statusColor,
    required IconData iconData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLightColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: statusColor == AppTheme.criticalColor ? AppTheme.criticalColor : AppTheme.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Manrope',
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  color: AppTheme.mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLightColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xu hướng tim mạch',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Manrope',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface2Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Tuần này',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (chartRecords.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(child: Text('Chưa có dữ liệu xu hướng')),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: chartRecords.map((r) => r.indicators['systolic']!).reduce((a, b) => a < b ? a : b) - 10,
                  maxY: chartRecords.map((r) => r.indicators['systolic']!).reduce((a, b) => a > b ? a : b) + 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.mutedTextColor.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                          if (value.toInt() < 0 || value.toInt() >= labels.length) return const SizedBox.shrink();
                          return Text(
                            labels[value.toInt() % labels.length],
                            style: const TextStyle(
                              color: AppTheme.mutedTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
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
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 1.5,
                            strokeColor: AppTheme.primaryColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryLightColor.withValues(alpha: 0.15),
                            AppTheme.primaryLightColor.withValues(alpha: 0.01),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text(
                'HUYẾT ÁP TÂM THU',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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

  void _showInputMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập dữ liệu sức khỏe',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.favorite, color: AppTheme.primaryColor),
              ),
              title: const Text('Nhập Sinh Tồn (Huyết áp, Nhịp tim)', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsInput()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.monitor_weight, color: AppTheme.accentColor),
              ),
              title: const Text('Nhập Chỉ Số Cơ Thể (Cân nặng, Chiều cao)', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BodyMetricsInput()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.warningColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.science, color: AppTheme.warningColor),
              ),
              title: const Text('Nhập Xét Nghiệm Máu (Đường huyết, Mỡ máu)', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodTestInput()));
              },
            ),
          ],
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

  Color _statusColor(String status) {
    return switch (status) {
      'Cao' => AppTheme.criticalColor,
      'Thấp' => AppTheme.warningColor,
      'Chưa có dữ liệu' => AppTheme.mutedTextColor,
      _ => AppTheme.primaryColor,
    };
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.3, size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
