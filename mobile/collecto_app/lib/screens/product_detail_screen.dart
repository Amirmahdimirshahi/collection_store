import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  final CartService cartService;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cartService,
  });

  void addToCart(BuildContext context) {
    final existingItems = cartService.items.where(
      (item) => item.product.id == product.id,
    );

    final currentQuantity = existingItems.isEmpty
        ? 0
        : existingItems.first.quantity;

    if (product.quantity <= currentQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موجودی این محصول کافی نیست.')),
      );
      return;
    }

    cartService.addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('محصول به سبد خرید اضافه شد.'),
        backgroundColor: Color(0xFF245B45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      appBar: AppBar(
        title: const Text('جزئیات محصول'),
        backgroundColor: const Color(0xFF245B45),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 100,
                color: Color(0xFF245B45),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('دسته‌بندی: ${product.category}'),
            const SizedBox(height: 20),
            const Text(
              'توضیحات محصول',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product.description.isEmpty
                  ? 'توضیحاتی برای این محصول ثبت نشده است.'
                  : product.description,
              style: const TextStyle(fontSize: 15, height: 1.8),
            ),
            const SizedBox(height: 20),
            Text(
              'قیمت: ${product.price} تومان',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF245B45),
              ),
            ),
            const SizedBox(height: 12),
            Text('موجودی: ${product.quantity} عدد'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: product.quantity > 0
                    ? () => addToCart(context)
                    : null,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('افزودن به سبد خرید'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF245B45),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
