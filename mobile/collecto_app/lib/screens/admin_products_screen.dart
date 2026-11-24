import 'package:flutter/material.dart';

import '../services/product_service.dart';
import 'add_product.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductService productService = ProductService();

  late Future<List<dynamic>> productsFuture;

  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
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
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );

    if (result == true && mounted) {
      setState(loadProducts);
    }
  }

  Future<void> editProduct(Map<String, dynamic> product) async {
    final nameController = TextEditingController(
      text: product['name']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: product['description']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: product['price']?.toString() ?? '',
    );

    final quantityController = TextEditingController(
      text: product['quantity']?.toString() ?? '',
    );

    String category = product['category']?.toString() ?? 'سایر';

    final formKey = GlobalKey<FormState>();

    final categories = ['سکه', 'اسکناس', 'تمبر', 'سایر'];

    if (!categories.contains(category)) {
      category = 'سایر';
    }

    final productId = int.tryParse(product['id'].toString());

    if (productId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('شناسه محصول معتبر نیست.')));

      nameController.dispose();
      descriptionController.dispose();
      priceController.dispose();
      quantityController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                          decoration: const InputDecoration(
                            labelText: 'نام محصول',
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'دسته‌بندی',
                          ),
                          items: categories.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                category = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'توضیحات',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'قیمت (تومان)',
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'موجودی',
                          ),
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
                        : () => Navigator.pop(dialogContext),
                    child: const Text('انصراف'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            try {
                              await productService.updateProduct(
                                productId: productId,
                                name: nameController.text.trim(),
                                category: category,
                                description: descriptionController.text.trim(),
                                price: int.parse(priceController.text.trim()),
                                quantity: int.parse(
                                  quantityController.text.trim(),
                                ),
                              );

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              if (!mounted) return;

                              setState(loadProducts);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('محصول ویرایش شد.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });

                              if (!dialogContext.mounted) return;

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('خطا در ویرایش: $e')),
                              );
                            }
                          },
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
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await productService.deleteProduct(productId);

      if (!mounted) return;

      setState(loadProducts);

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
                setState(loadProducts);
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
                        setState(loadProducts);
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
