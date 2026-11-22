
import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';

class CartScreen extends StatefulWidget {
  final CartService cartService;
  final int userId;

  const CartScreen({
    super.key,
    required this.cartService,
    required this.userId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService orderService = OrderService();

  bool isLoading = false;

  Future<void> submitOrder() async {
    final items = widget.cartService.items;

    if (items.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final orderItems = items.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
        };
      }).toList();

      final response = await orderService.createOrder(
        userId: widget.userId,
        items: orderItems,
      );

      widget.cartService.clearCart();

      if (!mounted) return;

      final order = response['order'];
      final orderId = order?['order_id'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'سفارش شما با موفقیت ثبت شد. شماره سفارش: $orderId',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ثبت سفارش ناموفق بود: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      appBar: AppBar(
        title: const Text('سبد خرید'),
        backgroundColor: const Color(0xFF245B45),
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: widget.cartService,
        builder: (context, child) {
          final items = widget.cartService.items;

          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'سبد خرید شما خالی است',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: Color(0xFF245B45),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'قیمت: ${item.product.price} تومان',
                                  ),
                                  Text(
                                    'جمع: ${item.totalPrice} تومان',
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          widget.cartService
                                              .decreaseQuantity(
                                            item.product.id,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        onPressed:
                                            item.quantity <
                                                item.product.quantity
                                            ? () {
                                                widget.cartService
                                                    .increaseQuantity(
                                                  item.product.id,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                widget.cartService.removeProduct(
                                  item.product.id,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تعداد کل محصولات:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.cartService.itemCount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'مبلغ قابل پرداخت:',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.cartService.totalPrice} تومان',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF245B45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF245B45),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(15),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('ادامه و ثبت سفارش'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
