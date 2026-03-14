import '../../domain/entities/progress_snapshot.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/local_progress_datasource.dart';

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._dataSource);

  final LocalProgressDataSource _dataSource;

  @override
  Future<ProgressSnapshot> fetchProgress() {
    return _dataSource.loadProgress();
  }
}

