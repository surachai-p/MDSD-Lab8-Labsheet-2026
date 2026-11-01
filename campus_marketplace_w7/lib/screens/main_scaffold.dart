import 'package:flutter/material.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/listing_draft_repository.dart';
import 'favorites_page.dart';
import 'home_page.dart';
import 'sell_item_page.dart';

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
  static const _favoritesTabIndex = 2;

  int _selectedIndex = 0;
  int _favoritesReloadCount = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == _favoritesTabIndex) _favoritesReloadCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        repository: widget.itemRepository,
        favoritesRepository: widget.favoritesRepository,
      ),
      SellItemPage(draftRepository: widget.draftRepository),
      // IndexedStack สร้างทุก Tab ตั้งแต่เปิดแอป initState จึงทำงานครั้งเดียว
      // เปลี่ยน Key ทุกครั้งที่เข้า Tab เพื่อให้สร้าง State ใหม่และโหลดรายการล่าสุด
      FavoritesPage(
        key: ValueKey(_favoritesReloadCount),
        repository: widget.favoritesRepository,
      ),
    ];

    return Scaffold(
      // IndexedStack เก็บ State ของทุก Tab ไว้ สลับ Tab แล้วรูปที่เลือกไม่หาย
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'ลงประกาศขาย',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'รายการโปรด',
          ),
        ],
      ),
    );
  }
}
