import 'package:flutter/material.dart';
import '../models/order.dart';

/// semua transaksi (tidak pernah dihapus)
ValueNotifier<List<Order>> allOrders = ValueNotifier([]);

/// transaksi shift yang sedang berjalan
ValueNotifier<List<Order>> shiftOrders = ValueNotifier([]);