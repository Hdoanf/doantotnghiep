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

  RecordType? _selectedFilter;

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
    if (user == null) {
      return const Center(
        child: Text(
          'Vui lòng đăng nhập',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 16),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Lịch sử',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterChips(),
        ),
      ),
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
                  'Không tải được dữ liệu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Manrope'),
                ),
              ),
            );
          }

          var records = snapshot.data ?? [];
          if (_selectedFilter != null) {
            records = records.where((r) => r.type == _selectedFilter).toList();
          }

          if (records.isEmpty) {
            return _emptyState();
          }

          final grouped = _groupByDay(records);

          return _buildTimeline(grouped);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip('Tất cả', null),
          const SizedBox(width: 8),
          _filterChip('Sinh tồn', RecordType.vitals),
          const SizedBox(width: 8),
          _filterChip('Xét nghiệm máu', RecordType.bloodTest),
          const SizedBox(width: 8),
          _filterChip('Chỉ số cơ thể', RecordType.bodyMetrics),
        ],
      ),
    );
  }

  Widget _filterChip(String label, RecordType? type) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isSelected ? Colors.white : AppTheme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.primaryColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy bắt đầu nhập chỉ số sức khỏe của bạn.',
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

  Map<DateTime, List<HealthRecord>> _groupByDay(List<HealthRecord> records) {
    final grouped = <DateTime, List<HealthRecord>>{};
    for (final record in records) {
      final day = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      grouped.putIfAbsent(day, () => []).add(record);
    }
    // Sort descending by day
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  String _formatDayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (day == today) return 'HÔM NAY';
    if (day == yesterday) return 'HÔM QUA';
    return DateFormat('dd/MM/yyyy').format(day);
  }

  Widget _buildTimeline(Map<DateTime, List<HealthRecord>> grouped) {
    return Stack(
      children: [
        // Continuous Vertical Track
        Positioned(
          left: 31,
          top: 24,
          bottom: 0,
          width: 2,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final day = grouped.keys.elementAt(index);
            final records = grouped[day]!;
            final isToday =
                day ==
                DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                );

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Stack(
                children: [
                  // Connector Node
                  Positioned(
                    left: 27,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppTheme.primaryColor
                            : AppTheme.mutedTextColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.backgroundColor,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 60, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDayHeader(day),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...records.map((r) => _buildRecordCard(r)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecordCard(HealthRecord record) {
    final typeColor = _getTypeColor(record.type);
    final typeLight = typeColor.withValues(alpha: 0.1);

    // Get a primary metric to show huge (like 120/80)
    String primaryValue = '';
    String primaryUnit = '';
    if (record.indicators.isNotEmpty) {
      if (record.indicators.containsKey('systolic') &&
          record.indicators.containsKey('diastolic')) {
        primaryValue =
            '${record.indicators['systolic']?.toInt() ?? '-'}/${record.indicators['diastolic']?.toInt() ?? '-'}';
        primaryUnit = 'mmHg';
      } else if (record.indicators.containsKey('heartRate')) {
        primaryValue = '${record.indicators['heartRate']?.toInt() ?? '-'}';
        primaryUnit = 'bpm';
      } else if (record.indicators.containsKey('glucose')) {
        primaryValue = '${record.indicators['glucose'] ?? '-'}';
        primaryUnit = 'mmol/L';
      } else {
        final first = record.indicators.values.first;
        primaryValue = '$first';
        primaryUnit = '';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecordDetailScreen(record: record)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.04),
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: typeLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getTypeIcon(record.type),
                        color: typeColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getTypeName(record.type),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(record),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (primaryValue.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    primaryValue,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    primaryUnit,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('HH:mm').format(record.date),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  if (record.indicators.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${record.indicators.length} chỉ số',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(HealthRecord record) {
    if (record.indicators.isEmpty) return AppTheme.normalColor;

    // We can't determine status purely from raw doubles without thresholds,
    // so we will just return a default active color or parse based on specific keys if needed.
    // For now, let's just use the primary color to indicate it has data.
    return AppTheme.primaryColor;
  }

  Color _getTypeColor(RecordType type) {
    switch (type) {
      case RecordType.bloodTest:
        return Colors.redAccent;
      case RecordType.vitals:
        return AppTheme.primaryColor;
      case RecordType.bodyMetrics:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(RecordType type) {
    switch (type) {
      case RecordType.bloodTest:
        return Icons.water_drop;
      case RecordType.vitals:
        return Icons.favorite;
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
