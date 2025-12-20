
class Medicine {
  final String id;
  final String name;
  final String? activeIngredient;
  final String? manufacturer;
  final String? unit;
  final double? price;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.name,
    this.activeIngredient,
    this.manufacturer,
    this.unit,
    this.price,
    this.description,
    this.imageUrl,
    required this.createdAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Medicine',
      activeIngredient: json['active_ingredient'],
      manufacturer: json['manufacturer'],
      unit: json['unit'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      description: json['description'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'active_ingredient': activeIngredient,
      'manufacturer': manufacturer,
      'unit': unit,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
  }
}
