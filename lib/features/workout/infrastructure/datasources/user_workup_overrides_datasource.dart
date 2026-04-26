import 'package:IAEntrenar/models/workup_day.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserWorkupOverridesDatasource {
  UserWorkupOverridesDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) {
    return _firestore.collection('users').doc(userId).collection('workup_overrides');
  }

  Future<List<WorkupDay>> getOverrides(String userId) async {
    final snap = await _col(userId).get();
    final list = snap.docs.map((d) => WorkupDay.fromJson(d.data())).toList();
    list.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return list;
  }

  Future<WorkupDay?> getOverride(String userId, int dayNumber) async {
    final doc = await _col(userId).doc(dayNumber.toString()).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return WorkupDay.fromJson(data);
  }

  Future<void> saveOverride(String userId, WorkupDay day, Map<String, dynamic> json) async {
    await _col(userId).doc(day.dayNumber.toString()).set(json, SetOptions(merge: true));
  }

  Future<void> deleteOverride(String userId, int dayNumber) async {
    await _col(userId).doc(dayNumber.toString()).delete();
  }
}

