class Product {
  final String name;
  final int price;
  final int stock;
  final String category;
  final String? image; 

  Product({
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    this.image, 
  });
}