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
}