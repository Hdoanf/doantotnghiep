import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../models/health_record.dart';
import '../input/blood_test_input.dart';
import '../input/vitals_input.dart';
import '../input/body_metrics_input.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HF Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<HealthRecord>>(
        stream: FirestoreService().getHealthRecords(user.uid),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${user.displayName != null && user.displayName!.isNotEmpty ? user.displayName : user.email.split('@')[0]}!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Hôm nay bạn cảm thấy thế nào?', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildAIReportButton(context, records),
                const SizedBox(height: 32),
                const Text('Xu hướng sức khỏe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildChart(records),
                const SizedBox(height: 32),
                const Text('Chỉ số gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSummaryCards(records),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIReportButton(BuildContext context, List<HealthRecord> records) {
    return Card(
      color: Colors.blue[50],
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.blue),
        title: const Text('Tạo báo cáo sức khỏe AI', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Phân tích tổng quát các chỉ số gần đây'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAIReport(context, records),
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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Báo cáo phân tích AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(report),
                  const SizedBox(height: 24),
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
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Widget _buildChart(List<HealthRecord> records) {
    // Lọc ra các bản ghi có nhịp tim hoặc chỉ số bất kỳ
    final chartRecords = records
        .where((r) => r.indicators.isNotEmpty)
        .take(7)
        .toList()
        .reversed
        .toList();

    if (chartRecords.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Chưa có dữ liệu xu hướng', style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      if (idx >= 0 && idx < chartRecords.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${chartRecords[idx].date.day}/${chartRecords[idx].date.month}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(chartRecords.length, (i) {
                    // Ưu tiên heart_rate, nếu không lấy chỉ số đầu tiên
                    final val = chartRecords[i].indicators['heart_rate'] ?? 
                               chartRecords[i].indicators.values.first;
                    return FlSpot(i.toDouble(), val);
                  }),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(context, Icons.bloodtype, 'Xét nghiệm', Colors.red, const BloodTestInput()),
        _actionButton(context, Icons.favorite, 'Sức khỏe', Colors.pink, const VitalsInput()),
        _actionButton(context, Icons.monitor_weight, 'Cơ thể', Colors.blue, const BodyMetricsInput()),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color, Widget screen) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryCards(List<HealthRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu chỉ số'));
    }

    double? systolic, diastolic, heartRate, glucose, weight;
    
    for (var r in records) {
      systolic ??= r.indicators['systolic'];
      diastolic ??= r.indicators['diastolic'];
      heartRate ??= r.indicators['heart_rate'];
      glucose ??= r.indicators['glucose'];
      weight ??= r.indicators['weight'];
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _summaryCard('Huyết áp', systolic != null && diastolic != null ? '${systolic.toInt()}/${diastolic.toInt()}' : '--', 'mmHg', Colors.green),
        _summaryCard('Nhịp tim', heartRate?.toInt().toString() ?? '--', 'bpm', Colors.green),
        _summaryCard('Đường huyết', glucose?.toString() ?? '--', 'mmol/L', Colors.green),
        _summaryCard('Cân nặng', weight?.toString() ?? '--', 'kg', Colors.blue),
      ],
    );
  }

  Widget _summaryCard(String title, String value, String unit, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
