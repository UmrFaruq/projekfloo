class Order {

  final String id;
  final String customer;
  final String paymentMethod;
  final DateTime date;

  final List<Map<String, dynamic>> items;

  final int subtotal;
  final int tax;
  final int total;

  Order({
    required this.id,
    required this.customer,
    required this.paymentMethod,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

}