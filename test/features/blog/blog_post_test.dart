import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/features/blog/domain/entities/blog_post.dart';

void main() {
  test('BlogPost.fromJson parses paginated API shape', () {
    final post = BlogPost.fromJson({
      'id': 67,
      'title': 'Sample Title',
      'slug': 'sample-title',
      'excerpt': 'some description',
      'coverImageUrl': null,
      'category': 'Home Decor',
      'tags': 'some tags',
      'publishedAt': '2026-06-09T09:03:22.470718Z',
      'createdAt': '2026-06-09T09:03:06.615355Z',
      'authorName': 'Admin User',
      'blocks': [
        {
          'id': 79,
          'blockType': 'TEXT',
          'content': 'content',
          'displayOrder': 0,
        },
      ],
    });

    expect(post.id, 67);
    expect(post.slug, 'sample-title');
    expect(post.blocks, hasLength(1));
    expect(post.blocks.first.blockType, 'TEXT');
  });
}
