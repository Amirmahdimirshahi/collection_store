import 'package:flutter/material.dart';

import '../services/admin_order_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String accessToken;

  const AdminOrdersScreen({super.key, required this.accessToken});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late final AdminOrderService orderService;

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? errorMessage;

  final Map<String, String> statusLabels = {
    'pending': 'در انتظار بررسی',
    'confirmed': 'تأیید شده',
    'shipped': 'ارسال شده',
    'delivered': 'تحویل شده',
    'cancelled': 'لغو شده',
  };

  @override
  void initState() {
    super.initState();
    orderService = AdminOrderService(accessToken: widget.accessToken);
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await orderService.getAllOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> changeStatus(int orderId, String newStatus) async {
    try {
      await orderService.updateOrderStatus(orderId: orderId, status: newStatus);

      if (!mounted) return;

      setState(() {
        final index = orders.indexWhere((order) => order['id'] == orderId);

        if (index != -1) {
          orders[index]['status'] = newStatus;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('وضعیت سفارش تغییر کرد.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String formatPrice(dynamic price) {
    final value = int.tryParse(price.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String formatDate(dynamic date) {
    if (date == null) return 'نامشخص';

    try {
      final parsed = DateTime.parse(date.toString()).toLocal();
      return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final int orderId = int.tryParse(order['id'].toString()) ?? 0;
    final String currentStatus = order['status']?.toString() ?? 'pending';

    final List items = order['items'] is List ? order['items'] as List : [];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'سفارش شماره $orderId',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  formatDate(order['created_at']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const Divider(height: 24),

            Text('نام مشتری: ${order['full_name'] ?? 'نامشخص'}'),
            const SizedBox(height: 5),
            Text('شماره تماس: ${order['phone_number'] ?? 'نامشخص'}'),

            const SizedBox(height: 12),
            const Text(
              'محصولات سفارش:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            ...items.map((item) {
              final product = Map<String, dynamic>.from(item);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${product['product_name'] ?? 'محصول'}  ×  ${product['quantity'] ?? 0}'
                  '  |  ${formatPrice(product['total_price'] ?? 0)} تومان',
                ),
              );
            }),

            const Divider(height: 24),

            Text(
              'مبلغ کل: ${formatPrice(order['total_price'] ?? 0)} تومان',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            const Text(
              'وضعیت سفارش:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              initialValue: statusLabels.containsKey(currentStatus)
                  ? currentStatus
                  : 'pending',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: statusLabels.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != currentStatus) {
                  changeStatus(orderId, value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت سفارش‌ها'),
        actions: [
          IconButton(
            onPressed: loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'بروزرسانی',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: loadOrders,
                      child: const Text('تلاش دوباره'),
                    ),
                  ],
                ),
              ),
            )
          : orders.isEmpty
          ? const Center(child: Text('هنوز هیچ سفارشی ثبت نشده است.'))
          : RefreshIndicator(
              onRefresh: loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return buildOrderCard(orders[index]);
                },
              ),
            ),
    );
  }
}
