
import 'package:flutter/material.dart';
import 'services/product_service.dart';

void main() {
  runApp(const CollectionStore());
}

class CollectionStore extends StatelessWidget {
  const CollectionStore({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Collection Store',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF245B45),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductService productService = ProductService();

  late Future<List<dynamic>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = productService.getProducts();
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F3),

        appBar: AppBar(
          backgroundColor: const Color(0xFF245B45),
          foregroundColor: Colors.white,
          title: const Text(
            'کالکتو',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {},
            ),
          ],
        ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'به دنیای کلکسیون خوش آمدید',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'کالاهای خاص، تاریخی و ارزشمند را کشف کنید.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  decoration: InputDecoration(
                    hintText: 'جستجوی سکه، اسکناس، تمبر و ...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'دسته‌بندی محصولات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      CategoryItem(
                        title: 'سکه',
                        icon: Icons.monetization_on,
                      ),
                      CategoryItem(
                        title: 'اسکناس',
                        icon: Icons.payments,
                      ),
                      CategoryItem(
                        title: 'تمبر',
                        icon: Icons.mail,
                      ),
                      CategoryItem(
                        title: 'اشیای قدیمی',
                        icon: Icons.watch,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'محصولات منتخب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                FutureBuilder<List<dynamic>>(
                  future: productsFuture,

                  builder: (context, snapshot) {

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                            color: Color(0xFF245B45),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'دریافت محصولات با خطا مواجه شد.',
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  productsFuture =
                                      productService.getProducts();
                                });
                              },
                              child: const Text('تلاش مجدد'),
                            ),
                          ],
                        ),
                      );
                    }

                    final products = snapshot.data ?? [];

                    if (products.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(25),
                          child: Text(
                            'هنوز محصولی ثبت نشده است.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final product =
                            products[index] as Map<String, dynamic>;

                        final name =
                            product['name']?.toString() ??
                            'بدون نام';

                        final category =
                            product['category']?.toString() ?? '';

                        final price =
                            product['price']?.toString() ??
                            'نامشخص';

                        return ProductCard(
                          name: name,
                          price: '$price تومان',
                          icon: getCategoryIcon(category),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              label: 'دسته‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              label: 'علاقه‌مندی',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'حساب من',
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const CategoryItem({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF245B45),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final IconData icon;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 55,
            color: const Color(0xFF245B45),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF245B45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
