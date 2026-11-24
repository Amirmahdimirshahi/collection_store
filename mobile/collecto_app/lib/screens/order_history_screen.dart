import 'package:flutter/material.dart';

import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  final int userId;

  const OrderHistoryScreen({super.key, required this.userId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService orderService = OrderService();

  late Future<List<Map<String, dynamic>>> ordersFuture;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void loadOrders() {
    ordersFuture = orderService.getUserOrders(userId: widget.userId);
  }

  String formatPrice(dynamic price) {
    final value = int.tryParse(price.toString()) ?? 0;
    return '${value.toString()} تومان';
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'در انتظار بررسی';
      case 'paid':
        return 'پرداخت شده';
      case 'completed':
        return 'تکمیل شده';
      case 'cancelled':
        return 'لغو شده';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچه سفارش‌ها'), centerTitle: true),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ordersFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 55, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('دریافت سفارش‌ها ناموفق بود.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        loadOrders();
                      });
                    },
                    child: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'هنوز سفارشی ثبت نکرده‌اید.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                loadOrders();
              });

              await ordersFuture;
            },

            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,

              itemBuilder: (context, index) {
                final order = orders[index];

                final items = order['items'] as List? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              'سفارش شماره ${order['id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            Text(
                              getStatusText(order['status'].toString()),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        ...items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [
                                Expanded(
                                  child: Text(item['product_name'].toString()),
                                ),

                                Text('تعداد: ${item['quantity']}'),
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            const Text(
                              'مبلغ کل:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            Text(
                              formatPrice(order['total_price']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'تاریخ ثبت: ${order['created_at']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
