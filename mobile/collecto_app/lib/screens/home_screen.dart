import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';

import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'admin_products_screen.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String userName;
  final String phoneNumber;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phoneNumber,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductService productService = ProductService();
  final CartService cartService = CartService();

  final TextEditingController searchController = TextEditingController();

  late Future<List<dynamic>> productsFuture;

  int? userId;
  late String userName;
  late String phoneNumber;

  String userRole = 'guest';

  // توکن احراز هویت کاربر
  String accessToken = '';

  String searchQuery = '';

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    userId = widget.userId == 0 ? null : widget.userId;
    userName = widget.userName;
    phoneNumber = widget.phoneNumber;

    userRole = widget.userId == 0 ? 'guest' : 'user';

    productsFuture = productService.getProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // دریافت اطلاعات کاربر و توکن پس از ورود
  void updateUser(Map<String, dynamic> user) {
    setState(() {
      userId = int.parse(user['id'].toString());

      userName = user['full_name']?.toString() ?? 'کاربر';

      phoneNumber = user['phone_number']?.toString() ?? '';

      userRole = user['role']?.toString() ?? 'user';

      final newToken = user['access_token']?.toString() ?? '';

      if (newToken.isNotEmpty) {
        accessToken = newToken;
      }
    });
  }

  Future<bool> ensureLogin() async {
    if (userId != null) {
      return true;
    }

    final user = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (!mounted || user == null) {
      return false;
    }

    updateUser(user);

    return true;
  }

  Future<void> openAccount() async {
    final loggedIn = await ensureLogin();

    if (!mounted || !loggedIn) return;

    setState(() {
      selectedIndex = 3;
    });
  }

  Future<void> openOrderHistory() async {
    final loggedIn = await ensureLogin();

    if (!mounted || !loggedIn) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderHistoryScreen(userId: userId!),
      ),
    );
  }

  // ورود به پنل مدیریت با ارسال توکن JWT
  Future<void> openAdminPanel() async {
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شما اجازه ورود به پنل مدیریت را ندارید.'),
        ),
      );
      return;
    }

    if (accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('توکن ورود مدیر موجود نیست. لطفاً دوباره وارد شوید.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminProductsScreen(accessToken: accessToken),
      ),
    );

    if (!mounted) return;

    setState(() {
      productsFuture = productService.getProducts();
    });
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

  List<dynamic> filterProducts(List<dynamic> products) {
    if (searchQuery.trim().isEmpty) {
      return products;
    }

    final query = searchQuery.trim().toLowerCase();

    return products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';

      final category = product['category']?.toString().toLowerCase() ?? '';

      final description =
          product['description']?.toString().toLowerCase() ?? '';

      return name.contains(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();
  }

  Future<void> onNavigationSelected(int index) async {
    if (index == 3) {
      await openAccount();
      return;
    }

    setState(() {
      selectedIndex = index;
    });

    if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بخش دسته‌بندی‌ها در حال تکمیل است.')),
      );
    } else if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بخش علاقه‌مندی‌ها در حال تکمیل است.')),
      );
    }
  }

  Widget buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'به دنیای کلکسیون خوش آمدید',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'کالاهای خاص، تاریخی و ارزشمند را کشف کنید.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'جستجوی سکه، اسکناس، تمبر و ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  CategoryItem(title: 'سکه', icon: Icons.monetization_on),
                  CategoryItem(title: 'اسکناس', icon: Icons.payments),
                  CategoryItem(title: 'تمبر', icon: Icons.mail),
                  CategoryItem(title: 'اشیای قدیمی', icon: Icons.watch),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Text(
              searchQuery.isEmpty ? 'محصولات منتخب' : 'نتایج جستجو',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            FutureBuilder<List<dynamic>>(
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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

                        const Text('دریافت محصولات با خطا مواجه شد.'),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              productsFuture = productService.getProducts();
                            });
                          },
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  );
                }

                final allProducts = snapshot.data ?? [];

                final products = filterProducts(allProducts);

                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Text(
                        searchQuery.isEmpty
                            ? 'هنوز محصولی ثبت نشده است.'
                            : 'محصولی با این مشخصات پیدا نشد.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index] as Map<String, dynamic>;

                    final name = product['name']?.toString() ?? 'بدون نام';

                    final category = product['category']?.toString() ?? '';

                    final price = product['price']?.toString() ?? 'نامشخص';

                    final productModel = ProductModel.fromJson(
                      Map<String, dynamic>.from(product),
                    );

                    return ProductCard(
                      name: name,
                      price: '$price تومان',
                      icon: getCategoryIcon(category),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: productModel,
                              cartService: cartService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAccountPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 25),

          const CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFF245B45),
            child: Icon(Icons.person, size: 55, color: Colors.white),
          ),

          const SizedBox(height: 18),

          Text(
            userName,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            phoneNumber,
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),

          const SizedBox(height: 10),

          Chip(
            avatar: Icon(
              userRole == 'admin'
                  ? Icons.admin_panel_settings
                  : Icons.person_outline,
              color: Colors.white,
            ),
            label: Text(userRole == 'admin' ? 'مدیر فروشگاه' : 'کاربر عادی'),
            backgroundColor: const Color(0xFF245B45),
            labelStyle: const TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 25),

          Card(
            elevation: 1,
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF245B45),
                  ),
                  title: const Text('نام کاربر'),
                  subtitle: Text(userName),
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF245B45),
                  ),
                  title: const Text('شماره تلفن'),
                  subtitle: Text(phoneNumber),
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF245B45),
                  ),
                  title: const Text('شناسه کاربری'),
                  subtitle: Text(userId?.toString() ?? 'ثبت نشده'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 1,
            color: Colors.white,
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF245B45),
              ),
              title: const Text(
                'تاریخچه سفارش‌ها',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('مشاهده سفارش‌هایی که ثبت کرده‌اید'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: openOrderHistory,
            ),
          ),

          if (userRole == 'admin') ...[
            const SizedBox(height: 20),

            Card(
              elevation: 1,
              color: Colors.white,
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF245B45),
                ),
                title: const Text(
                  'پنل مدیریت فروشگاه',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('مدیریت محصولات و موجودی فروشگاه'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: openAdminPanel,
              ),
            ),
          ],

          const SizedBox(height: 25),

          const Text(
            'کالکتو؛ دنیای کالاهای خاص و کلکسیونی',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
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

          title: const Text(
            'کالکتو',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),

          centerTitle: true,

          leading: PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'orders') {
                openOrderHistory();
              } else if (value == 'account') {
                openAccount();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined),
                    SizedBox(width: 10),
                    Text('تاریخچه سفارش‌ها'),
                  ],
                ),
              ),

              const PopupMenuItem<String>(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 10),
                    Text('حساب من'),
                  ],
                ),
              ),
            ],
          ),

          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () async {
                final user = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      cartService: cartService,
                      userId: userId ?? 0,
                    ),
                  ),
                );

                if (!mounted || user == null) return;

                updateUser(user);
              },
            ),
          ],
        ),

        body: selectedIndex == 3 ? buildAccountPage() : buildHomePage(),

        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onNavigationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
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
              selectedIcon: Icon(Icons.person),
              label: 'حساب من',
            ),
          ],
        ),
      ),
    );
  }
}
