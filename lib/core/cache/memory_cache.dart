/// In-memory stale-while-revalidate cache for API responses.
class MemoryCache {
  MemoryCache._();
  static final MemoryCache instance = MemoryCache._();

  final _entries = <String, _CacheEntry<dynamic>>{};

  T? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _entries.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 5)}) {
    _entries[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  void invalidate(String key) => _entries.remove(key);

  void invalidatePrefix(String prefix) {
    _entries.removeWhere((k, _) => k.startsWith(prefix));
  }

  void clear() => _entries.clear();

  /// Returns cached value immediately if present; always fetches fresh data.
  /// [onFresh] is called when new data arrives (update UI).
  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetch,
    Duration ttl = const Duration(minutes: 5),
    bool forceRefresh = false,
    void Function(T fresh)? onFresh,
  }) async {
    final cached = !forceRefresh ? get<T>(key) : null;
    if (cached != null) {
      // Revalidate in background without blocking.
      fetch().then((fresh) {
        set(key, fresh, ttl: ttl);
        onFresh?.call(fresh);
      }).ignore();
      return cached;
    }
    final fresh = await fetch();
    set(key, fresh, ttl: ttl);
    return fresh;
  }
}

class _CacheEntry<T> {
  _CacheEntry(this.value, this.expiresAt);
  final T value;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
