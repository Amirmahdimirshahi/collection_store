class ProductModel {
  final int id;
  final String name;
  final String category;
  final String description;
  final int price;
  final int quantity;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.quantity,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
    );
  }
}
