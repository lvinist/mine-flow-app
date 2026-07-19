import 'package:hive/hive.dart';

/// Generic Clean Architecture local cache repository wrapping a Hive [Box].
/// Provides typed local read/write/delete operations for cached models.
class HiveCacheRepository<T> {
  final Box<T> box;

  HiveCacheRepository(this.box);

  /// Retrieves a single cached item by its unique ID, returning null if not found.
  T? get(String id) {
    return box.get(id);
  }

  /// Retrieves all cached items as an unmodifiable list.
  List<T> getAll() {
    return box.values.toList();
  }

  /// Persists or updates a single cached item by key.
  Future<void> put(String id, T item) async {
    await box.put(id, item);
  }

  /// Persists a collection of items in a single bulk transaction.
  Future<void> putAll(Map<String, T> items) async {
    await box.putAll(items);
  }

  /// Deletes a cached item by key.
  Future<void> delete(String id) async {
    await box.delete(id);
  }

  /// Clears all entries from this storage box.
  Future<void> clear() async {
    await box.clear();
  }

  /// Total count of items stored in this cache box.
  int get length => box.length;

  /// Returns true if the storage box contains zero elements.
  bool get isEmpty => box.isEmpty;

  /// Returns true if the key exists in cache.
  bool containsKey(String id) => box.containsKey(id);

  /// Emits updated list of items whenever the underlying Hive box changes.
  Stream<List<T>> watchAll() {
    return box.watch().map((_) => box.values.toList());
  }
}
