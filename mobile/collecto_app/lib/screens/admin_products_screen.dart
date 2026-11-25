import 'package:flutter/material.dart';

import '../services/product_service.dart';
import 'add_product.dart';

class AdminProductsScreen extends StatefulWidget {
  final String accessToken;

  const AdminProductsScreen({super.key, required this.accessToken});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late final ProductService productService;
  late Future<List<dynamic>> productsFuture;

  bool isDeleting = false;

  @override
  void initState() {
    super.initState();

    productService = ProductService(accessToken: widget.accessToken);

    loadProducts();
  }

  void loadProducts() {
    productsFuture = productService.getProducts();
  }

  Future<void> refreshProducts() async {
    setState(() {
      loadProducts();
    });

    await productsFuture;
  }

  Future<void> openAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(accessToken: widget.accessToken),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        loadProducts();
      });
    }
  }

  Future<void> editProduct(Map<String, dynamic> product) async {
    final productId = int.tryParse(product['id'].toString());

    if (productId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('شناسه محصول معتبر نیست.')));
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return EditProductDialog(
          product: product,
          productId: productId,
          productService: productService,
        );
      },
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        loadProducts();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('محصول ویرایش شد.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> deleteProduct(Map<String, dynamic> product) async {
    final productId = int.tryParse(product['id'].toString());

    if (productId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('شناسه محصول معتبر نیست.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف محصول'),
          content: Text('آیا از حذف «${product['name']}» اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await productService.deleteProduct(productId);

      if (!mounted) return;

      setState(() {
        loadProducts();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('محصول حذف شد.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطا در حذف محصول: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  Widget buildProductCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'بدون نام';
    final category = product['category']?.toString() ?? 'سایر';
    final price = product['price']?.toString() ?? '0';
    final quantity = product['quantity']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE6EFE9),
                  child: Icon(Icons.inventory_2, color: Color(0xFF245B45)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      editProduct(product);
                    } else if (value == 'delete') {
                      deleteProduct(product);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text('قیمت: $price تومان'),
            const SizedBox(height: 6),
            Text('موجودی: $quantity عدد'),
          ],
        ),
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
          title: const Text('مدیریت محصولات'),
          centerTitle: true,
          backgroundColor: const Color(0xFF245B45),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  loadProducts();
                });
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'بروزرسانی',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAddProduct,
          backgroundColor: const Color(0xFF245B45),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('افزودن محصول'),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 45,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text('دریافت محصولات ناموفق بود.'),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          loadProducts();
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
              return const Center(child: Text('هنوز محصولی ثبت نشده است.'));
            }

            return RefreshIndicator(
              onRefresh: refreshProducts,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = Map<String, dynamic>.from(
                    products[index] as Map,
                  );

                  return buildProductCard(product);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final int productId;
  final ProductService productService;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.productId,
    required this.productService,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController quantityController;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final List<String> categories = ['سکه', 'اسکناس', 'تمبر', 'سایر'];

  late String category;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.product['name']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.product['description']?.toString() ?? '',
    );

    priceController = TextEditingController(
      text: widget.product['price']?.toString() ?? '',
    );

    quantityController = TextEditingController(
      text: widget.product['quantity']?.toString() ?? '',
    );

    category = widget.product['category']?.toString() ?? 'سایر';

    if (!categories.contains(category)) {
      category = 'سایر';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();

    super.dispose();
  }

  // ذخیره تغییرات محصول
  Future<void> saveProduct() async {
    if (isSaving) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await widget.productService.updateProduct(
        productId: widget.productId,
        name: nameController.text.trim(),
        category: category,
        description: descriptionController.text.trim(),
        price: int.parse(priceController.text.trim()),
        quantity: int.parse(quantityController.text.trim()),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطا در ویرایش: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('ویرایش محصول'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'نام محصول'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام محصول را وارد کنید';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                  items: categories.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              category = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'توضیحات'),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'قیمت (تومان)'),
                  validator: (value) {
                    final price = int.tryParse(value ?? '');

                    if (price == null || price <= 0) {
                      return 'قیمت معتبر وارد کنید';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'موجودی'),
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');

                    if (quantity == null || quantity < 0) {
                      return 'موجودی معتبر وارد کنید';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving
                ? null
                : () {
                    Navigator.pop(context, false);
                  },
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: isSaving ? null : saveProduct,
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ذخیره تغییرات'),
          ),
        ],
      ),
    );
  }
}
