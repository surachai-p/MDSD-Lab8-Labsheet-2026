import 'package:flutter/material.dart';
import '../repositories/item_repository.dart';
// เพิ่ม import 3 บรรทัดนี้
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';
import 'favorites_page.dart';

import 'home_page.dart';
import 'sell_item_page.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';

class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // แก้ไข pages ให้มี 3 หน้า และส่ง Parameter ให้ครบ
    final pages = [
      HomePage(
        repository: widget.itemRepository,
        favoritesRepository: widget.favoritesRepository,
      ),
      SellItemPage(
        draftRepository: widget.draftRepository,
      ), // เอา const ออกและส่ง draftRepository เรียบร้อย
      FavoritesPage(repository: widget.favoritesRepository),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        // เพิ่ม Tab รายการโปรด ให้ครบ 3 อัน
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
        ],
      ),
      // ส่วนของ FAB (ปุ่มตะกร้า) ปล่อยไว้เหมือนเดิม
    );
  }
}