class Product {
  final String id;
  final String name;
  final int price;
  final String category;
  final String? image;
  final int qty; // SUDAH DIGANTI JADI QTY

  Product({
    this.id = '', 
    required this.name,
    required this.price,
    required this.category,
    this.image,
    this.qty = 0, // DEFAULT NYA JUGA QTY
  });
}