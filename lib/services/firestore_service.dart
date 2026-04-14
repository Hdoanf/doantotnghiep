import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<HealthRecord>> getHealthRecords(String userId) {
    return _db
        .collection('health_records')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthRecord.fromFirestore(doc))
            .toList());
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
