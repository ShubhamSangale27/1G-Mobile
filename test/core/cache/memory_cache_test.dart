import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/core/cache/memory_cache.dart';

void main() {
  setUp(() => MemoryCache.instance.clear());

  test('caches and returns value within TTL', () async {
    var calls = 0;
    final v1 = await MemoryCache.instance.getOrFetch(
      key: 'k',
      fetch: () async {
        calls++;
        return 'data';
      },
    );
    final v2 = await MemoryCache.instance.getOrFetch(
      key: 'k',
      fetch: () async {
        calls++;
        return 'new';
      },
    );
    expect(v1, 'data');
    expect(v2, 'data');
    // Second call returns cache and triggers background revalidation.
    expect(calls, greaterThanOrEqualTo(1));
  });

  test('forceRefresh bypasses cache', () async {
    var calls = 0;
    await MemoryCache.instance.getOrFetch(key: 'k', fetch: () async { calls++; return 1; });
    await MemoryCache.instance.getOrFetch(
      key: 'k',
      forceRefresh: true,
      fetch: () async { calls++; return 2; },
    );
    expect(calls, 2);
  });
}
