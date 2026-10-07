import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// นำเข้า Model และ Repository ที่ต้องใช้ (ตรวจสอบพาธให้ตรงกับไฟล์ของคุณ)
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart'; // เพิ่มการเรียกใช้ FavoritesRepository

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  final FavoritesRepository
  favoritesRepository; // เพิ่ม field สำหรับรับ FavoritesRepository

  const HomePage({
    super.key,
    required this.repository,
    required this.favoritesRepository, // บังคับรับค่าผ่าน Constructor
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลสินค้าตอนเริ่มต้น
    _itemsFuture = widget.repository.getItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Marketplace')),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีสินค้า'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 50),
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('฿${item.price.toStringAsFixed(2)}'),

                // -----------------------------------------------------------------
                // แก้ไข trailing จากปุ่มตะกร้าปุ่มเดียว เป็น Row ที่มี 2 ปุ่ม (หัวใจ + ตะกร้า)
                // -----------------------------------------------------------------
                trailing: Row(
                  mainAxisSize: MainAxisSize
                      .min, // สำคัญมาก ไม่งั้น Row จะกินพื้นที่จน Error
                  children: [
                    // ปุ่มที่ 1: ไอคอนรูปหัวใจ สำหรับเพิ่มรายการโปรด
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      color: Colors.red,
                      onPressed: () async {
                        try {
                          // บันทึกลงฐานข้อมูล
                          await widget.favoritesRepository.addFavorite(
                            item.id,
                            item.title,
                            item.price,
                            item.imageUrl,
                          );
                          // แสดงแจ้งเตือนเมื่อสำเร็จ
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('เพิ่มลงรายการโปรดแล้ว'),
                              ),
                            );
                          }
                        } catch (e) {
                          // แสดงแจ้งเตือนเมื่อเกิดข้อผิดพลาด (เช่น กดซ้ำ)
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                            );
                          }
                        }
                      },
                    ),

                    // ปุ่มที่ 2: ไอคอนตะกร้า สำหรับเพิ่มลงตะกร้า
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        // เปลี่ยนจาก addItem เป็น add ให้ตรงกับ CartModel
                        Provider.of<CartModel>(
                          context,
                          listen: false,
                        ).add(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')),
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
