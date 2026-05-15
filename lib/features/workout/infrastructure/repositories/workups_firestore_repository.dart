import 'package:IAEntrenar/features/workout/infrastructure/datasources/workups_firestore_datasource.dart';
import 'package:IAEntrenar/models/workup_day.dart';

class WorkupsFirestoreRepository {

  final WorkupsFirestoreDatasource _datasource;

  WorkupsFirestoreRepository(this._datasource);

  Future<List<WorkupDay>> getWorkupDays() async {
    return _datasource.getWorkupDays();
  }

  Future<List<WorkupDay>> getWorkupDaysForUser(String userId) async {
    return _datasource.getWorkupDaysMergedWithOverrides(userId: userId);
  }
}