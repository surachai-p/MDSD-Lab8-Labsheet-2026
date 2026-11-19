class ListingDraft {
  const ListingDraft({
    required this.title,
    required this.category,
    required this.description,
  });

  final String title;
  final String category;
  final String description;

  factory ListingDraft.fromJson(Map<String, dynamic> json) => ListingDraft(
    title: json['title'] as String,
    category: json['category'] as String,
    description: json['description'] as String,
  );
}
