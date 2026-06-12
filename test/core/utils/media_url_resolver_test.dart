import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/core/utils/media_url_resolver.dart';

void main() {
  group('MediaUrlResolver YouTube', () {
    test('extracts id from watch, youtu.be, shorts URLs', () {
      expect(
        MediaUrlResolver.extractYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        MediaUrlResolver.extractYouTubeVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        MediaUrlResolver.extractYouTubeVideoId('https://youtube.com/shorts/l-wG-dsoGHU'),
        'l-wG-dsoGHU',
      );
    });

    test('embed URL includes origin for WebView policy', () {
      const resolver = MediaUrlResolver('');
      final embed = resolver.resolveVideoEmbedUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(embed, contains('youtube.com/embed/dQw4w9WgXcQ'));
      expect(embed, contains('origin=${Uri.encodeComponent(MediaUrlResolver.embedOrigin)}'));
      expect(embed, contains('playsinline=1'));
    });

    test('buildVideoEmbedHtml sets referrer policy on iframe', () {
      const embed = 'https://www.youtube.com/embed/test?origin=https%3A%2F%2Fwww.1guntha.com';
      final html = MediaUrlResolver.buildVideoEmbedHtml(embed);
      expect(html, contains('referrerpolicy="strict-origin-when-cross-origin"'));
      expect(html, contains('meta name="referrer" content="strict-origin-when-cross-origin"'));
      expect(html, contains(embed));
    });
  });
}
