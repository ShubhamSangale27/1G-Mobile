class BlogPost {
  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.coverImageUrl,
    this.category,
    this.tags,
    this.publishedAt,
    required this.createdAt,
    this.authorName,
    this.blocks = const [],
  });

  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? coverImageUrl;
  final String? category;
  final String? tags;
  final String? publishedAt;
  final String createdAt;
  final String? authorName;
  final List<BlogContentBlock> blocks;

  List<String> get tagList {
    if (tags == null || tags!.trim().isEmpty) return [];
    return tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final blocksJson = json['blocks'] as List<dynamic>? ?? [];
    return BlogPost(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      excerpt: json['excerpt'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      category: json['category'] as String?,
      tags: json['tags'] as String?,
      publishedAt: json['publishedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      authorName: json['authorName'] as String?,
      blocks: blocksJson
          .map((e) => BlogContentBlock.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => (a.displayOrder).compareTo(b.displayOrder)),
    );
  }
}

class BlogContentBlock {
  const BlogContentBlock({
    this.id,
    required this.blockType,
    this.content,
    this.mediaUrl,
    this.linkUrl,
    this.caption,
    this.displayOrder = 0,
  });

  final int? id;
  final String blockType;
  final String? content;
  final String? mediaUrl;
  final String? linkUrl;
  final String? caption;
  final int displayOrder;

  factory BlogContentBlock.fromJson(Map<String, dynamic> json) {
    return BlogContentBlock(
      id: json['id'] as int?,
      blockType: json['blockType'] as String? ?? 'TEXT',
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      linkUrl: json['linkUrl'] as String?,
      caption: json['caption'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}

class BlogFilters {
  const BlogFilters({this.categories = const [], this.tags = const []});

  final List<String> categories;
  final List<String> tags;

  factory BlogFilters.fromJson(Map<String, dynamic> json) {
    return BlogFilters(
      categories: (json['categories'] as List<dynamic>? ?? []).cast<String>(),
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
