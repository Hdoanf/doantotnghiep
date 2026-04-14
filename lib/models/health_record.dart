import 'package:cloud_firestore/cloud_firestore.dart';

enum RecordType { bloodTest, vitals, bodyMetrics }

class HealthRecord {
  final String id;
  final String userId;
  final DateTime date;
  final RecordType type;
  final Map<String, double> indicators;
  final String? note;

  HealthRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.indicators,
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
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'type': type.toString(),
      'indicators': indicators,
      'note': note,
    };
  }
}
