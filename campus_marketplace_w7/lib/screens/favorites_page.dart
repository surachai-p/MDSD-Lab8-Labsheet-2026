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
    _loadFavorites();
  }

  @override
  void didUpdateWidget(covariant FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    _favoritesFuture = widget.repository.getAllFavorites();
  }

  Future<void> _removeFavorite(int itemId, String title) async {
    try {
      await widget.repository.removeFavorite(itemId);
      if (mounted) {
        setState(() {
          _loadFavorites();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบ "$title" ออกจากรายการโปรดแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการโปรด'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: () {
              setState(() {
                _loadFavorites();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadFavorites();
          });
          await _favoritesFuture;
        },
        child: FutureBuilder<List<FavoriteItem>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }
            final favorites = snapshot.data ?? [];
            if (favorites.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'ลบออกจากรายการโปรด',
                    onPressed: () => _removeFavorite(item.itemId, item.title),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
