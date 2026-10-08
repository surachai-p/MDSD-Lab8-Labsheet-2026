import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;
  final bool isActive;

  const FavoritesPage({
    super.key,
    required this.repository,
    this.isActive = true,
  });

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

  @override
  void didUpdateWidget(covariant FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!oldWidget.isActive && widget.isActive) ||
        oldWidget.repository != widget.repository) {
      _favoritesFuture = widget.repository.getAllFavorites();
    }
  }

  Future<void> _removeFavorite(FavoriteItem favorite) async {
    try {
      await widget.repository.removeFavorite(favorite.itemId);
      if (!mounted) return;
      setState(() {
        _favoritesFuture = widget.repository.getAllFavorites();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบ "${favorite.title}" ออกจากรายการโปรดแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบรายการโปรดไม่สำเร็จ: $error')),
      );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('โหลดรายการโปรดไม่สำเร็จ: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _favoritesFuture = widget.repository.getAllFavorites();
                      });
                    },
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
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
              final favorite = favorites[index];
              return ListTile(
                leading: Image.network(
                  favorite.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                title: Text(favorite.title),
                subtitle: Text('${favorite.price} บาท'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'ลบออกจากรายการโปรด',
                  onPressed: () => _removeFavorite(favorite),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
