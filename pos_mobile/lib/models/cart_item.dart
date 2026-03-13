class CartItem {
  final String name;
  final int price;
  int qty;

  CartItem({
    required this.name,
    required this.price,
    this.qty = 1,
  });
}