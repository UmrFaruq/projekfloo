class Product {
  final String id;
  final String name;
  final int price;
  final String category;
  final String? image;
  final int qty; 
  final String unit; // <--- TAMBAHKAN INI

  Product({
    this.id = '', 
    required this.name,
    required this.price,
    required this.category,
    this.image,
    this.qty = 0,
    this.unit = 'pcs', // <--- KASIH DEFAULT 'pcs' BIAR AMAN
  });
}