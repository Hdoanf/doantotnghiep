import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<HealthRecord>> getHealthRecords(String userId) {
    return _healthRecordsQuery(userId).snapshots().map(_recordsFromSnapshot);
  }

  Stream<List<HealthRecord>> getRecentHealthRecords(
    String userId, {
    int limit = 20,
  }) {
    return _healthRecordsQuery(
      userId,
    ).limit(limit).snapshots().map(_recordsFromSnapshot);
  }

  Query<Map<String, dynamic>> _healthRecordsQuery(String userId) {
    return _db.collection('health_records').where('userId', isEqualTo: userId);
  }

  List<HealthRecord> _recordsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final records = snapshot.docs
        .map((doc) => HealthRecord.fromFirestore(doc))
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<void> addHealthRecord(HealthRecord record) {
    return _db.collection('health_records').add(record.toFirestore());
  }

  Future<void> updateHealthRecord(HealthRecord record) {
    return _db
        .collection('health_records')
        .doc(record.id)
        .update(record.toFirestore());
  }

  Future<void> deleteHealthRecord(String id) {
    return _db.collection('health_records').doc(id).delete();
  }
}
