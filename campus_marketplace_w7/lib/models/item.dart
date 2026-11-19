class Item {
  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'] as int,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    description: json['description'] as String,
    category: json['category'] as String,
    imageUrl: json['image'] as String,
  );
}
