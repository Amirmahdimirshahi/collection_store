import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/favorite_service.dart';

class FavoritesScreen extends StatefulWidget {
  final String accessToken;

  const FavoritesScreen({super.key, required this.accessToken});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoriteService favoriteService;
  late Future<List<ProductModel>> favoritesFuture;

  @override
  void initState() {
    super.initState();

    favoriteService = FavoriteService(accessToken: widget.accessToken);

    favoritesFuture = favoriteService.getFavorites();
  }

  Future<void> refreshFavorites() async {
    setState(() {
      favoritesFuture = favoriteService.getFavorites();
    });

    await favoritesFuture;
  }

  Future<void> removeFavorite(int productId) async {
    try {
      await favoriteService.removeFavorite(productId);

      if (!mounted) return;

      setState(() {
        favoritesFuture = favoriteService.getFavorites();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('محصول از علاقه‌مندی‌ها حذف شد.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطا در حذف محصول: $error')));
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'سکه':
        return Icons.monetization_on;
      case 'اسکناس':
        return Icons.payments;
      case 'تمبر':
        return Icons.mail;
      default:
        return Icons.watch;
    }
  }

  Widget buildFavoritesList(List<ProductModel> favorites) {
    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 75, color: Colors.grey),
            SizedBox(height: 15),
            Text(
              'هنوز محصولی به علاقه‌مندی‌ها اضافه نکرده‌اید.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final product = favorites[index];

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFE8F0EB),
                child: Icon(
                  getCategoryIcon(product.category),
                  color: const Color(0xFF245B45),
                  size: 28,
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  '${product.price} تومان',
                  style: const TextStyle(color: Color(0xFF245B45)),
                ),
              ),
              trailing: IconButton(
                tooltip: 'حذف از علاقه‌مندی‌ها',
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => removeFavorite(product.id),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFF245B45),
          foregroundColor: Colors.white,
          title: const Text('علاقه‌مندی‌های من'),
          centerTitle: true,
        ),
        body: FutureBuilder<List<ProductModel>>(
          future: favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF245B45)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    const Text('دریافت علاقه‌مندی‌ها ناموفق بود.'),
                    TextButton(
                      onPressed: refreshFavorites,
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              );
            }

            final favorites = snapshot.data ?? [];

            return buildFavoritesList(favorites);
          },
        ),
      ),
    );
  }
}
