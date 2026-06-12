import '../../features/property/domain/entities/property.dart';
import 'media_url_resolver.dart';

enum GallerySlideKind { photo, videoEmbed }

class GallerySlide {
  const GallerySlide({
    required this.kind,
    required this.sourceUrl,
    this.embedPlayUrl,
  });

  final GallerySlideKind kind;
  final String sourceUrl;
  final String? embedPlayUrl;
}

/// Port of Angular `property-gallery.util.ts`.
List<GallerySlide> buildGallerySlides(List<PropertyImage>? images) {
  if (images == null || images.isEmpty) return [];
  final sorted = [...images]..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
  const resolver = MediaUrlResolver('');
  final out = <GallerySlide>[];

  for (final item in sorted) {
    final url = item.imageUrl.trim();
    if (url.isEmpty) continue;
    final isVideo = item.mediaType == MediaType.video ||
        resolver.resolveVideoEmbedUrl(url) != null;

    if (isVideo) {
      final embed = resolver.resolveVideoEmbedUrl(url);
      if (embed != null && embed.isNotEmpty) {
        out.add(GallerySlide(kind: GallerySlideKind.videoEmbed, sourceUrl: url, embedPlayUrl: embed));
        continue;
      }
    }
    out.add(GallerySlide(kind: GallerySlideKind.photo, sourceUrl: url));
  }
  return out;
}

/// Best thumbnail for property cards (image or video poster).
String propertyCardThumbnailUrl(Property property, MediaUrlResolver resolver) {
  final images = property.images;
  if (images == null || images.isEmpty) return '';

  final sorted = [...images]..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));

  for (final item in sorted) {
    if (item.mediaType == MediaType.video) {
      final poster = resolver.resolveVideoPoster(item.imageUrl);
      if (poster != null && poster.isNotEmpty) return poster;
    }
  }

  for (final item in sorted) {
    if (item.mediaType == MediaType.image) {
      final resolved = resolver.resolvePropertyImageUrl(item.imageUrl);
      if (resolved.isNotEmpty) return resolved;
    }
  }

  for (final item in sorted) {
    final resolved = resolver.resolvePropertyImageUrl(item.imageUrl);
    if (resolved.isNotEmpty) return resolved;
  }

  return '';
}

bool propertyHasVideo(Property property) {
  final images = property.images ?? [];
  final resolver = const MediaUrlResolver('');
  return images.any(
    (i) => i.mediaType == MediaType.video || resolver.resolveVideoEmbedUrl(i.imageUrl) != null,
  );
}
