import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/ble_service.dart';
import '../../services/firestore_service.dart';

class LiveVitalsScreen extends StatefulWidget {
  const LiveVitalsScreen({super.key});

  @override
  State<LiveVitalsScreen> createState() => _LiveVitalsScreenState();
}

class _LiveVitalsScreenState extends State<LiveVitalsScreen> {
  final BleService _bleService = BleService();
  final List<FlSpot> _rawSpots = [];
  double _lastX = 0;

  double _currentBpm = 0;
  double _currentSpO2 = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bleService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentBpm = (data['bpm'] as num?)?.toDouble() ?? 0.0;
          _currentSpO2 = (data['spo2'] as num?)?.toDouble() ?? 0.0;

          double raw = (data['raw'] as num?)?.toDouble() ?? 0.0;
          _rawSpots.add(FlSpot(_lastX, raw));
          _lastX += 1;

          if (_rawSpots.length > 100) {
            _rawSpots.removeAt(0);
          }
        });
      }
    });
  }

  void _saveData() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    if (_currentBpm == 0 && _currentSpO2 == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có dữ liệu để lưu.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final record = HealthRecord(
        id: '',
        userId: user.uid,
        date: DateTime.now(),
        type: RecordType.vitals,
        indicators: {'heart_rate': _currentBpm, 'spO2': _currentSpO2},
      );
      await FirestoreService().addHealthRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kết quả thành công.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    // We don't necessarily want to disconnect here if the user just navigates back,
    // but for this app flow, we'll disconnect to be safe.
    _bleService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Theo dõi trực tiếp',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.secondaryTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<BluetoothConnectionState>(
            stream: _bleService.connectionState,
            initialData: BluetoothConnectionState.connected,
            builder: (context, snapshot) {
              final state = snapshot.data;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  state == BluetoothConnectionState.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: state == BluetoothConnectionState.connected
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLiveMetrics(),
            const SizedBox(height: 24),
            _buildLiveGraph(),
            const SizedBox(height: 32),
            _buildInstructions(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveData,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text(
                  'Lưu kết quả hiện tại',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetrics() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            title: 'Nhịp tim',
            value: _currentBpm > 0 ? _currentBpm.toStringAsFixed(0) : '--',
            unit: 'BPM',
            icon: Icons.favorite,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            title: 'SpO2',
            value: _currentSpO2 > 0 ? _currentSpO2.toStringAsFixed(1) : '--',
            unit: '%',
            icon: Icons.air,
            color: AppTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              fontFamily: 'Manrope',
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveGraph() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Tín hiệu PPG (Xung nhịp)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: _rawSpots.isNotEmpty ? _rawSpots.first.x : 0,
                maxX: _rawSpots.isNotEmpty ? _rawSpots.last.x : 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: _rawSpots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.2),
                          AppTheme.primaryColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentLightColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đặt ngón tay trỏ nhẹ nhàng lên cảm biến MAX30102 và giữ yên để có kết quả chính xác nhất.',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
