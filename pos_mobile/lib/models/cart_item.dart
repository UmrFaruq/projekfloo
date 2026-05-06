class CartItem {
  final String id; // <-- Tambahan variabel untuk ID unik
  final String name;
  final int price;
  final String? image; // <-- Tambahan variabel untuk nampung link gambar
  int qty;

  CartItem({
    required this.id, // <-- Pastikan ID juga diisi saat membuat CartItem
    required this.name,
    required this.price,
    this.image, // <-- Jangan lupa dipanggil di sini
    this.qty = 1,
  });
}