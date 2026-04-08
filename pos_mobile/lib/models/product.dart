class Product {
  final String id;
  final String name;
  final int price;
  final String category;
  final String? image;
  final int stock;

  Product({
    this.id = '', 
    required this.name,
    required this.price,
    required this.category,
    this.image,
    this.stock = 0,
  });
}