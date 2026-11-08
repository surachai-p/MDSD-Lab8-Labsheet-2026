import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository favoritesRepository;

  const FavoritesPage({super.key, required this.favoritesRepository});

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

  void _loadFavorites() {
    _favoritesFuture = widget.favoritesRepository.getAllFavorites();
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    try {
      await widget.favoritesRepository.removeFavorite(item.itemId);

      if (!mounted) return;

      setState(_loadFavorites);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบ "${item.title}" ออกจากรายการโปรดแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบรายการโปรดไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('โหลดรายการโปรดไม่สำเร็จ: ${snapshot.error}'),
              ),
            );
          }

          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ'),
            );
          }

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
                subtitle: Text('${item.price.toStringAsFixed(2)} บาท'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'ลบรายการโปรด',
                  onPressed: () => _removeFavorite(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
