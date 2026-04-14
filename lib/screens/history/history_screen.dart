import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/health_record.dart';
import 'record_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null) return const Center(child: Text('Vui lòng đăng nhập'));

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử sức khỏe')),
      body: StreamBuilder<List<HealthRecord>>(
        stream: FirestoreService().getHealthRecords(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu'));
          }

          final records = snapshot.data!;
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(record.type),
                    child: Icon(_getTypeIcon(record.type), color: Colors.white),
                  ),
                  title: Text(_getTypeName(record.type)),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(record.date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordDetailScreen(record: record),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
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
