import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../models/item.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/item_repository.dart';
import '../services/gemini_service.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.favoritesRepository,
  });

  final ItemRepository repository;
  final FavoritesRepository favoritesRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
  }

  Future<void> _testGemini() async {
    try {
      final message = await GeminiService().generateText(
        'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง',
      );
      debugPrint('Gemini: $message');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gemini error: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            tooltip: 'ทดสอบ Gemini แบบข้อความ',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _testGemini,
          ),
          IconButton(
            icon: Badge(
              label: Text('${cart.itemCount}'),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CheckoutPage())),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'เกิดข้อผิดพลาด: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '\$${item.price.toStringAsFixed(2)} • ${item.category}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        tooltip: 'เพิ่มในรายการโปรด',
                        onPressed: () async {
                          try {
                            await widget.favoritesRepository.addFavorite(
                              item.id,
                              item.title,
                              item.price,
                              item.imageUrl,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'เพิ่ม "${item.title}" ในรายการโปรดแล้ว'),
                                ),
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'ไม่สามารถเพิ่มในรายการโปรดได้: $error'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      FilledButton(
                        onPressed: () {
                          context.read<CartModel>().add(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('เพิ่ม ${item.title} ลงตะกร้าแล้ว'),
                            ),
                          );
                        },
                        child: const Text('เพิ่ม'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
