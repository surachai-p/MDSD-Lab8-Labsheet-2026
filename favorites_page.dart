import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;

  const FavoritesPage({super.key, required this.repository});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = widget.repository.getAllFavorites();
  }

  // โหลดรายการโปรดใหม่ — เรียกหลังจากลบเพื่ออัปเดต FutureBuilder
  void _reload() {
    setState(() {
      _favoritesFuture = widget.repository.getAllFavorites();
    });
  }

  Future<void> _removeFavorite(int itemId, String title) async {
    try {
      await widget.repository.removeFavorite(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบ "$title" ออกจากรายการโปรดแล้ว')),
        );
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการโปรด'),
      ),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          // สถานะที่ 1: กำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // สถานะที่ 2: เกิดข้อผิดพลาด
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final favorites = snapshot.data ?? [];

          // สถานะที่ 3: รายการว่างเปล่า
          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรายการโปรด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ลองกดหัวใจที่หน้าหลักดูสิ ❤️',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // สถานะที่ 4: มีข้อมูล
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  tooltip: 'ลบออกจากรายการโปรด',
                  onPressed: () => _removeFavorite(item.itemId, item.title),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
