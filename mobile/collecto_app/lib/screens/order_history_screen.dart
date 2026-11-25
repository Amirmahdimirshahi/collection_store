import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  final int userId;
  final String accessToken;

  const OrderHistoryScreen({
    super.key,
    required this.userId,
    required this.accessToken,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrderService orderService;
  late Future<List<Map<String, dynamic>>> ordersFuture;

  @override
  void initState() {
    super.initState();

    orderService = OrderService(accessToken: widget.accessToken);

    loadOrders();
  }

  void loadOrders() {
    ordersFuture = orderService.getUserOrders(userId: widget.userId);
  }

  Future<void> refreshOrders() async {
    setState(() {
      loadOrders();
    });

    await ordersFuture;
  }

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }

    return value;
  }

  String formatPrice(dynamic price) {
    final value = int.tryParse(price.toString()) ?? 0;

    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '${toPersianDigits(formatted)} تومان';
  }

  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'در انتظار بررسی';

      case 'confirmed':
        return 'تأیید شده';

      case 'shipped':
        return 'ارسال شده';

      case 'delivered':
        return 'تحویل شده';

      case 'cancelled':
        return 'لغو شده';

      case 'paid':
        return 'پرداخت شده';

      case 'completed':
        return 'تکمیل شده';

      default:
        return 'نامشخص';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;

      case 'confirmed':
        return Colors.blue;

      case 'shipped':
        return Colors.indigo;

      case 'delivered':
      case 'completed':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String formatDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'تاریخ نامشخص';
    }

    try {
      String dateString = value.toString().trim();

      if (dateString.contains(' ') && !dateString.contains('T')) {
        dateString = dateString.replaceFirst(' ', 'T');
      }

      DateTime date;

      final hasTimezone =
          dateString.endsWith('Z') ||
          RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(dateString);

      if (hasTimezone) {
        date = DateTime.parse(dateString).toLocal();
      } else {
        date = DateTime.parse('${dateString}Z').toLocal();
      }

      final jalali = Jalali.fromDateTime(date);

      final year = jalali.formatter.yyyy;
      final month = jalali.formatter.mm;
      final day = jalali.formatter.dd;

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      final dateText = '$year/$month/$day';
      final timeText = '$hour:$minute';

      return '${toPersianDigits(dateText)} - ${toPersianDigits(timeText)}';
    } catch (_) {
      return 'تاریخ نامشخص';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تاریخچه سفارش‌ها'),
          centerTitle: true,
        ),
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
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                      color: Colors.red,
                    ),
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
              onRefresh: refreshOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];

                  final items = order['items'] as List? ?? [];

                  final status = order['status']?.toString() ?? '';

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
                              Expanded(
                                child: Text(
                                  'سفارش شماره ${toPersianDigits(order['id'].toString())}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  getStatusText(status),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: getStatusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          const Text(
                            'محصولات سفارش:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          ...items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['product_name']?.toString() ??
                                          'محصول',
                                    ),
                                  ),
                                  Text(
                                    'تعداد: ${toPersianDigits(item['quantity'].toString())}',
                                  ),
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

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'تاریخ ثبت: ${formatDateTime(order['created_at'])}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
