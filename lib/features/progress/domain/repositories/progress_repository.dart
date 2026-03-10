import '../entities/progress_snapshot.dart';

abstract class ProgressRepository {
  Future<ProgressSnapshot> fetchProgress();
}

