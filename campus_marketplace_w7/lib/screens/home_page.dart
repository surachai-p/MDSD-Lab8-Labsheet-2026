import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../services/gemini_service.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  final FavoritesRepository favoritesRepository;

  const HomePage({
    super.key,
    required this.repository,
    required this.favoritesRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;
  final Set<int> _favoriteItemIds = {};

  // ── ปุ่มทดสอบ Gemini ชั่วคราว (Checkpoint 2.1) ──────────────────────────
  bool _geminiLoading = false;

  Future<void> _testGemini() async {
    setState(() => _geminiLoading = true);
    try {
      final result = await GeminiService().generateText(
        'ช่วยคิดประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง โดยไม่ต้องมีชื่อร้านค้า ',
      );
      debugPrint('=== Gemini Response ===\n$result');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), duration: const Duration(seconds: 6)),
        );
      }
    } catch (e) {
      debugPrint('=== Gemini Error ===\n$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _geminiLoading = false);
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
    _loadFavoritesState();
  }

  Future<void> _loadFavoritesState() async {
    try {
      final favs = await widget.favoritesRepository.getAllFavorites();
      if (mounted) {
        setState(() {
          _favoriteItemIds.clear();
          _favoriteItemIds.addAll(favs.map((f) => f.itemId));
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          // ── ปุ่มทดสอบชั่วคราว Checkpoint 2.1 ──
          _geminiLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'ทดสอบ Gemini',
                  onPressed: _testGemini,
                ),
          // ────────────────────────────────────────
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้า'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isFavorite = _favoriteItemIds.contains(item.id);
              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                title: Text(item.title),
                subtitle: Text('${item.price} บาท'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : null,
                      ),
                      tooltip: isFavorite ? 'อยู่ในรายการโปรดแล้ว' : 'เพิ่มในรายการโปรด',
                      onPressed: () async {
                        try {
                          await widget.favoritesRepository.addFavorite(
                            item.id,
                            item.title,
                            item.price,
                            item.imageUrl,
                          );
                          if (context.mounted) {
                            setState(() {
                              _favoriteItemIds.add(item.id);
                            });
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text('เพิ่ม "${item.title}" ในรายการโปรดแล้ว'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text('เกิดข้อผิดพลาด: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        context.read<CartModel>().add(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
