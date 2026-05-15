import 'package:IAEntrenar/models/workup_day.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkupsFirestoreDatasource {

  WorkupsFirestoreDatasource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collectionName = "workouts";

  Future<List<WorkupDay>> getWorkupDays() async {
    final snap = await _firestore.collection(_collectionName).get();
    final list = snap.docs
        .map((doc) => WorkupDay.fromJson(doc.data()))
        .toList();
    list.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return list;
  }

  Future<List<WorkupDay>> getWorkupDaysMergedWithOverrides({
    required String userId,
  }) async {
    final base = await getWorkupDays();
    final overridesSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workup_overrides')
        .get();

    if (overridesSnap.docs.isEmpty) return base;
    final overrides = overridesSnap.docs
        .map((d) => WorkupDay.fromJson(d.data()))
        .toList();

    final byDay = {for (final d in base) d.dayNumber: d};
    for (final o in overrides) {
      byDay[o.dayNumber] = o;
    }

    final merged = byDay.values.toList()..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return merged;
  }
}