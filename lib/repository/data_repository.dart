import '../services/api_service.dart';
import '../services/hive_store.dart';

enum DataSource { api, cache }

class SyncResult {
  SyncResult({required this.source, this.error, this.itemsCount = 0});

  final DataSource source;
  final String? error;
  final int itemsCount;

  bool get hasError => error != null;
}

/// Pulls fresh data from the API (http://localhost:3000) and persists it to
/// Hive. The screens always read from Hive, which is the single source of
/// truth for the UI - the API never feeds the UI directly.
class DataRepository {
  DataRepository({ApiService? apiService, HiveStore? store})
      : api = apiService ?? ApiService(),
        store = store ?? HiveStore();

  final ApiService api;
  final HiveStore store;

  Future<SyncResult> refreshAll() async {
    try {
      final (scores, courses, pdfs) = await (
        api.fetchScores(),
        api.fetchNewCourses(),
        api.fetchPdfs(),
      ).wait;

      await (
        store.saveScores(scores),
        store.saveCourses(courses),
        store.savePdfs(pdfs),
      ).wait;

      return SyncResult(
        source: DataSource.api,
        itemsCount: scores.length + courses.length + pdfs.length,
      );
    } on ApiException catch (e) {
      return SyncResult(source: DataSource.cache, error: e.message);
    } catch (e) {
      return SyncResult(source: DataSource.cache, error: e.toString());
    }
  }
}

extension _Wait3<A, B, C> on (Future<A>, Future<B>, Future<C>) {
  Future<(A, B, C)> get wait async => (
        await this.$1,
        await this.$2,
        await this.$3,
      );
}
