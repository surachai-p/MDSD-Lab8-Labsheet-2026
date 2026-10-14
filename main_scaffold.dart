import 'package:flutter/material.dart';
import 'home_page.dart';
import 'sell_item_page.dart';
import 'favorites_page.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';

class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository? draftRepository; // จะมีจริงหลังทำส่วนที่ 5 เสร็จ

  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    this.draftRepository,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Tab 1: หน้าหลัก
      HomePage(
        repository: widget.itemRepository,
        favoritesRepository: widget.favoritesRepository,
      ),
      // Tab 2: ลงประกาศขาย — ส่ง draftRepository เข้าไป (จะใช้จริงในส่วนที่ 5)
      SellItemPage(draftRepository: widget.draftRepository),
      // Tab 3: รายการโปรด (ใช้ UniqueKey เพื่อบังคับให้โหลดข้อมูลใหม่ทุกครั้งที่สลับ Tab)
      FavoritesPage(key: UniqueKey(), repository: widget.favoritesRepository),
    ];

    return Scaffold(
      // IndexedStack เก็บ State ของทุก Tab ไว้พร้อมกัน สลับ Tab แล้วข้อมูลที่กรอก/เลือกไว้ไม่หาย
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
        ],
      ),
    );
  }
}
