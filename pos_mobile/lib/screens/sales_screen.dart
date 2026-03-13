import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../data/product_data.dart';
import '../models/product.dart';
import '../data/cart_data.dart';
import 'dashboard_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import '../data/shift_data.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {

  String selectedCategory = "Semua";
  String searchQuery = "";

  List<Product> getFilteredProducts() {

    return products.where((product) {

      bool matchCategory =
          selectedCategory == "Semua" ||
          product.category == selectedCategory;

      bool matchSearch =
          product.name.toLowerCase().contains(searchQuery);

      return matchCategory && matchSearch;

    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    final filteredProducts = getFilteredProducts();

    return Scaffold(
      backgroundColor: PastelColors.mint,

      drawer: const SizedBox(
        width: 250,
        child: AppDrawer(),
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// NAVBAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 28),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),

                  Row(
                    children: [

                      /// CART ICON
                      Stack(
                        children: [

                          IconButton(
                            icon: const Icon(Icons.shopping_cart),
                            onPressed: () async {

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CartScreen(),
                                ),
                              );

                            },
                          ),

                          Positioned(
                            right: 4,
                            top: 4,

                            child: ValueListenableBuilder(
                              valueListenable: cartNotifier,

                              builder: (context, value, child) {

                                if (value == 0) {
                                  return const SizedBox();
                                }

                                return Container(
                                  padding: const EdgeInsets.all(4),

                                  decoration: const BoxDecoration(
                                    color: PastelColors.rose,
                                    shape: BoxShape.circle,
                                  ),

                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),

                                  child: Text(
                                    value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),

                      /// PROFILE ICON
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: PastelColors.teal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),

              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: TextField(

                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },

                  decoration: const InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: "Search product...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// CATEGORY
            SizedBox(
              height: 40,

              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),

                children: [

                  CategoryChip(
                    title: "Semua",
                    isSelected: selectedCategory == "Semua",
                    onTap: () {
                      setState(() {
                        selectedCategory = "Semua";
                      });
                    },
                  ),

                  CategoryChip(
                    title: "Makanan Instan",
                    isSelected: selectedCategory == "Makanan Instan",
                    onTap: () {
                      setState(() {
                        selectedCategory = "Makanan Instan";
                      });
                    },
                  ),

                  CategoryChip(
                    title: "Minuman",
                    isSelected: selectedCategory == "Minuman",
                    onTap: () {
                      setState(() {
                        selectedCategory = "Minuman";
                      });
                    },
                  ),

                  CategoryChip(
                    title: "Snack",
                    isSelected: selectedCategory == "Snack",
                    onTap: () {
                      setState(() {
                        selectedCategory = "Snack";
                      });
                    },
                  ),

                  CategoryChip(
                    title: "Sembako",
                    isSelected: selectedCategory == "Sembako",
                    onTap: () {
                      setState(() {
                        selectedCategory = "Sembako";
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// PRODUCT GRID
            Expanded(
              child: GridView.builder(

                padding: const EdgeInsets.symmetric(horizontal: 16),

                itemCount: filteredProducts.length,

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),

                itemBuilder: (context, index) {

                  return ProductCard(
                    product: filteredProducts[index],
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [

          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: PastelColors.sage,
            ),
            child: Row(
              children: [

                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: PastelColors.sage,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Cashier1",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    Text(
                      "Cashier",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          Expanded(
            child: ListView(
              children: [

                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text("Dashboard"),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.point_of_sale),
                  title: const Text("Sales"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text("Order History"),
                onTap: () {

                  if (!shiftActive.value) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Start shift first"),
                      ),
                    );

                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  );
                },
              ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () {

                    if (shiftActive.value) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("End shift first before logout"),
                        ),
                      );

                      return;
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}