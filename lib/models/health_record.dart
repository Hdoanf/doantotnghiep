import 'package:cloud_firestore/cloud_firestore.dart';

enum RecordType { bloodTest, vitals, bodyMetrics }

class HealthRecord {
  final String id;
  final String userId;
  final DateTime date;
  final RecordType type;
  final Map<String, double> indicators;
  final List<double>? historyData; // New field for graph history
  final String? note;

  HealthRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.indicators,
    this.historyData,
    this.note,
  });

  factory HealthRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return HealthRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: RecordType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => RecordType.vitals,
      ),
      indicators: (data['indicators'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      historyData: data['historyData'] != null 
          ? List<double>.from((data['historyData'] as List).map((e) => (e as num).toDouble()))
          : null,
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'type': type.toString(),
      'indicators': indicators,
      'historyData': historyData,
      'note': note,
    };
  }
}
