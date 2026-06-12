class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final raw = json['content'];
    final list = raw is List
        ? raw.map((e) => fromJsonT(e as Map<String, dynamic>)).toList()
        : <T>[];
    return PageResponse(
      content: list,
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? list.length,
      totalElements: json['totalElements'] as int? ?? list.length,
      totalPages: json['totalPages'] as int? ?? 1,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
    );
  }

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
}
