# ใบงานปฏิบัติสัปดาห์ที่ 8: Local Database & Persistence ด้วย Drift

**วิชา** การพัฒนาซอฟต์แวร์สำหรับอุปกรณ์เคลื่อนที่ | **เครื่องมือ** Flutter, Drift, sqlite3_flutter_libs, build_runner, Google AI Studio

> 🔗 **ความต่อเนื่องของโปรเจกต์:** ใบงานนี้สืบทอดโดยตรงจากโปรเจกต์ **`campus_marketplace_w7`** ที่ทำไว้จนจบใบงานการทดลองที่ 7 ตอนนี้โปรเจกต์มี: หน้า **Home** ที่ดึงสินค้าจริงจาก Fake Store API (สัปดาห์ 6), ตะกร้าสินค้า (`CartModel`, สัปดาห์ 5), หน้า **"ลงประกาศขายสินค้า" (Sell)** ที่ใช้ Gemini Vision ช่วยแนะนำ title/category/description จากรูปภาพ (สัปดาห์ 7) และโครง **Bottom Navigation Bar** (`MainScaffold`) ที่มี 2 Tab แรกคือ "หน้าหลัก" กับ "ลงประกาศขาย"  **ยังไม่มี** ฟีเจอร์ "ถูกใจ" (Favorites) และร่างประกาศที่ AI ช่วยแนะนำ หลังกดยืนยันจะถูกเก็บไว้ใน State ชั่วคราวของ `SellItemPage` เท่านั้น **หายไปทันทีที่ปิดแอป**
>
> สัปดาห์นี้คือจุดที่ฟีเจอร์ **"รายการโปรด" (Favorites) ถูกสร้างขึ้น** พร้อมกันกับการนำร่างประกาศมาบันทึกถาวร ทั้งสองฟีเจอร์จะเข้าถึงข้อมูลผ่าน **Repository Pattern** เช่นเดียวกับที่ `ItemRepository`/`ItemRepositoryApi` ทำกับ REST API ในสัปดาห์ที่ 6 **ทำต่อในโฟลเดอร์ `campus_marketplace_w7` เดิม ห้ามสร้างโปรเจกต์ใหม่แยกต่างหาก** 

---

## วัตถุประสงค์การเรียนรู้

เมื่อทำใบงานนี้เสร็จสิ้น ผู้เรียนจะสามารถ

1. ใช้ AI ช่วยร่างโครงสร้างตาราง (Schema) จากคำอธิบายฟีเจอร์เป็นภาษาธรรมชาติ แล้วประเมิน/ปรับแก้ด้วยตนเอง
2. ติดตั้งและตั้งค่า Drift พร้อมรัน Code Generation ด้วย `build_runner` ได้ถูกต้อง
3. ประกาศตาราง (`Table`) และคลาสฐานข้อมูล (`AppDatabase`) ตามหลักการที่เรียนในบทหนังสือเรียนหัวข้อ 8.4
4. ออกแบบและเขียน Repository Pattern (Interface + Implementation) สำหรับ Local Database เองได้ โดยไม่ต้องมีตัวอย่างสำเร็จรูปครบทุกเมธอด
5. สร้างฟีเจอร์ "ถูกใจ" (Favorites) และนำร่างประกาศขายสินค้าจากสัปดาห์ที่ 7 มาบันทึกถาวรด้วย Drift ได้จริง
6. เพิ่ม Tab ใหม่เข้า Bottom Navigation Bar (`MainScaffold`) ที่มีอยู่แล้วได้ โดยไม่กระทบโค้ดของ Tab เดิม
7. ทดสอบและยืนยันว่าแอปทำงานแบบ Offline-first ได้จริง คือข้อมูลไม่หายแม้ปิดแอปหรือปิดอินเทอร์เน็ต

## สิ่งที่ต้องเตรียมก่อนเริ่ม

- โปรเจกต์ `campus_marketplace_w7` จากใบงานการทดลองที่ 7 ที่รันได้ปกติครบทุก Checkpoint แล้ว (มีหน้า Home, Checkout, Sell พร้อม `MainScaffold` 2 Tab)
- บัญชี Google AI Studio ที่ใช้มาตั้งแต่สัปดาห์ที่ 1
- ติดตั้ง Flutter SDK เวอร์ชันล่าสุดที่รองรับ Null Safety เต็มรูปแบบ (ตรวจสอบด้วย `flutter --version`)

⚠️ **ข้อควรระวัง**: การเปลี่ยนโครงสร้างตาราง (เพิ่ม/ลบ/แก้ไขคอลัมน์) หลังรัน `build_runner` ไปแล้วครั้งหนึ่ง ต้องรันคำสั่งเดิมซ้ำทุกครั้ง มิเช่นนั้นไฟล์ `.g.dart` จะไม่ตรงกับโค้ดล่าสุดและโปรเจกต์จะไม่คอมไพล์ผ่าน หากเจอปัญหานี้ให้ดูหัวข้อ Troubleshooting ท้ายใบงาน

---

## ส่วนที่ 1: ใช้ AI ช่วยร่าง Schema ก่อนเขียนโค้ด

ตามหลักการในบทหนังสือเรียนหัวข้อ 8.3 การออกแบบ Schema ต้องทำก่อนเขียนโค้ดเสมอ สัปดาห์นี้จะฝึกใช้ Gemini ช่วยร่าง Schema เบื้องต้น แล้วนำมาตรวจสอบและปรับแก้ด้วยตนเอง เพราะ AI ช่วยคิดได้เร็ว แต่การตัดสินใจสุดท้ายต้องเป็นของนักพัฒนาเสมอ (หลักการเดียวกับที่เรียนเรื่อง Responsible AI ในสัปดาห์ที่ 7)

### ขั้นตอนที่ 1.1 🔧 ทำตามขั้นตอน

เปิด Google AI Studio (https://aistudio.google.com) แล้วส่ง Prompt นี้ให้ Gemini

```
ฉันกำลังพัฒนาแอป Flutter ชื่อ Campus Marketplace ด้วย Drift (ORM สำหรับ SQLite)
ต้องการออกแบบตารางสองตาราง

1. เก็บรายการสินค้าที่ผู้ใช้กดถูกใจเป็นครั้งแรก 
   ต้องรู้ว่าถูกใจสินค้าชิ้นไหน (อ้างอิงจาก id สินค้าที่เป็นตัวเลข)
   เก็บชื่อ ราคา รูปภาพไว้ด้วยเพื่อแสดงผลได้โดยไม่ต้องเรียก API ซ้ำ และต้องเรียงตามเวลาที่กดถูกใจล่าสุดได้

2. เก็บร่างประกาศขายสินค้าที่ AI ช่วยแนะนำจากรูปภาพ (ปัจจุบันเก็บไว้ใน State ชั่วคราวเท่านั้น หายเมื่อปิดแอป)
   มีชื่อประกาศ หมวดหมู่ คำบรรยาย และ path ของรูปภาพในเครื่อง ต้องรู้ว่าแก้ไขล่าสุดเมื่อไหร่

ช่วยร่างโค้ด Dart ของ Class ที่ extends Table ทั้งสองตาราง พร้อมระบุชนิดข้อมูล (Column type)
ของแต่ละคอลัมน์ และเหตุผลว่าทำไมเลือกชนิดข้อมูลนั้น
```

บันทึกโค้ดที่ Gemini ตอบกลับมาที่ด้านล่าง

```text
import React, { useState } from 'react';
import { 
  Heart, 
  Sparkles, 
  Database, 
  Code2, 
  FileCode, 
  Clock, 
  Copy, 
  Check, 
  BookOpen, 
  Info, 
  PlusCircle, 
  Trash2, 
  Edit3, 
  ArrowUpDown,
  Laptop,
  CheckCircle2,
  XCircle,
  AlertTriangle
} from 'lucide-react';

interface FavoriteItem {
  id: number;
  itemId: number;
  title: string;
  price: number;
  imageUrl: string;
  addedAt: string;
}

interface DraftItem {
  id: number;
  title: string;
  category: string;
  description: string;
  imagePath: string;
  updatedAt: string;
}

export default function App() {
  const [activeTab, setActiveTab] = useState<'review' | 'code' | 'simulator' | 'comparison'>('review');
  const [copiedId, setCopiedId] = useState<string | null>(null);

  // Mock Data following Course Syllabus (MDAD-2026 Week 8)
  const [favorites, setFavorites] = useState<FavoriteItem[]>([
    {
      id: 1,
      itemId: 101,
      title: 'Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops',
      price: 109.95,
      imageUrl: 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
      addedAt: '2026-10-06 14:10:12',
    },
    {
      id: 2,
      itemId: 102,
      title: 'Mens Casual Premium Slim Fit T-Shirts',
      price: 22.3,
      imageUrl: 'https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_.jpg',
      addedAt: '2026-10-06 14:02:45',
    },
    {
      id: 3,
      itemId: 103,
      title: 'John Hardy Women\'s Legends Naga Gold & Silver Dragon Station Chain Bracelet',
      price: 695.0,
      imageUrl: 'https://fakestoreapi.com/img/71pWzhdJNwL._AC_UL640_QL65_ML3_.jpg',
      addedAt: '2026-10-06 13:45:00',
    },
  ]);

  const [drafts, setDrafts] = useState<DraftItem[]>([
    {
      id: 1,
      title: 'เครื่องคิดเลขวิทยาศาสตร์ Casio fx-991EX',
      category: 'อุปกรณ์การเรียน',
      description: 'AI ตรวจพบ: เครื่องคิดเลขสภาพดี หน้าจอคมชัด ปุ่มกดทำงานปกติ แถมซองหนังแท้',
      imagePath: '/data/user/0/com.campus.marketplace/app_flutter/ai_draft_172820.jpg',
      updatedAt: '2026-10-06 14:20:33',
    },
    {
      id: 2,
      title: 'จักรยานแม่บ้านญี่ปุ่น สำหรับปั่นใน ม.',
      category: 'ยานพาหนะ/จักรยาน',
      description: 'AI ตรวจพบ: จักรยานทรงญี่ปุ่น สีขาวครีม มีตะกร้าหน้าพร้อมใช้งาน',
      imagePath: '/data/user/0/com.campus.marketplace/app_flutter/ai_draft_172821.jpg',
      updatedAt: '2026-10-06 13:55:10',
    },
  ]);

  const [sortOrder, setSortOrder] = useState<'desc' | 'asc'>('desc');
  const [duplicateAlert, setDuplicateAlert] = useState<string | null>(null);

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const sortedFavorites = [...favorites].sort((a, b) => {
    return sortOrder === 'desc' 
      ? new Date(b.addedAt).getTime() - new Date(a.addedAt).getTime()
      : new Date(a.addedAt).getTime() - new Date(b.addedAt).getTime();
  });

  const handleAddFavorite = (candidateItemId: number) => {
    // Check Unique constraint
    const existing = favorites.find(f => f.itemId === candidateItemId);
    if (existing) {
      setDuplicateAlert(`⚠️ สินค้า itemId: ${candidateItemId} มีอยู่ในตารางแล้ว! ข้อบังคับ .unique() ป้องกันการเพิ่มซ้ำ`);
      setTimeout(() => setDuplicateAlert(null), 3500);
      return;
    }

    const nextId = favorites.length > 0 ? Math.max(...favorites.map(f => f.id)) + 1 : 1;
    const now = new Date();
    const dateStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
    
    setFavorites([
      {
        id: nextId,
        itemId: candidateItemId,
        title: `สินค้าตัวอย่างจาก Fake Store API #${candidateItemId}`,
        price: 150.0,
        imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&auto=format&fit=crop&q=80',
        addedAt: dateStr,
      },
      ...favorites
    ]);
  };

  const perfectDartCode = `import 'package:drift/drift.dart';

// -----------------------------------------------------------------------------
// ตารางที่ 1: favorite_items (ตรงตามเอกสารสัปดาห์ที่ 8)
// -----------------------------------------------------------------------------
@DataClassName('FavoriteItem')
class FavoriteItems extends Table {
  // 1. Primary Key: เลขรันของแถวในฐานข้อมูลเครื่อง (Auto-increment Integer)
  IntColumn get id => integer().autoIncrement()();

  // 2. รหัสสินค้าจาก Fake Store API: กำหนด .unique() เพื่อป้องกันไม่ให้ถูกใจสินค้าชิ้นเดียวกันซ้ำหลายแถว
  IntColumn get itemId => integer().unique()();

  // 3. สำเนาข้อมูล (Denormalized Copy): เก็บไว้แสดงผลออฟไลน์ได้ทันทีโดยไม่ต้องเรียก API ซ้ำ
  TextColumn get title => text()();
  TextColumn get imageUrl => text()();

  // 4. ราคาสินค้า ณ ตอนกดถูกใจ: เลือก RealColumn (double ใน Dart) เพื่อรองรับทศนิยมถูกต้อง
  RealColumn get price => real()();

  // 5. วันเวลาที่กดถูกใจ: ใช้สำหรับ ORDER BY added_at DESC
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

// -----------------------------------------------------------------------------
// ตารางที่ 2: listing_drafts (ตรงตามเอกสารสัปดาห์ที่ 8)
// -----------------------------------------------------------------------------
@DataClassName('ListingDraft')
class ListingDrafts extends Table {
  // 1. Primary Key: เลขรันของร่างแต่ละฉบับ (Auto-increment Integer)
  IntColumn get id => integer().autoIncrement()();

  // 2. ข้อมูลสินค้าที่ AI แนะนำและผู้ใช้แก้ไขได้
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get description => text()();

  // 3. Path รูปภาพในเครื่องที่ใช้วิเคราะห์ด้วย Gemini Vision (เก็บเป็น Text Path แทน BLOB)
  TextColumn get imagePath => text()();

  // 4. วันเวลาที่แก้ไขล่าสุด: ใช้เรียงลำดับแบบร่างที่เพิ่งทำค้างไว้
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}`;

  const repositoryCode = `// lib/data/repositories/favorites_repository_drift.dart
import 'package:drift/drift.dart';
import '../local/app_database.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;
  FavoritesRepositoryDrift(this._db);

  @override
  Future<void> addFavorite(int itemId, String title, double price, String imageUrl) {
    // จุดนี้คือ Offline-first: เขียนลง SQLite ในเครื่องโดยตรง 
    // ไม่มี http.post() หรือ Dio เรียกเซิร์ฟเวอร์เลยสักบรรทัด
    return _db.into(_db.favoriteItems).insert(
      FavoriteItemsCompanion.insert(
        itemId: itemId,
        title: title,
        price: price,
        imageUrl: imageUrl,
      ),
      // เมื่อ itemId เป็น .unique() การใช้ insertOrIgnore จะข้ามเงียบๆ แทนที่จะ Error
      mode: InsertMode.insertOrIgnore,
    );
  }

  @override
  Stream<List<FavoriteItem>> getAllFavorites() {
    return (_db.select(_db.favoriteItems)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .watch();
  }

  @override
  Future<void> removeFavorite(int itemId) {
    return (_db.delete(_db.favoriteItems)..where((t) => t.itemId.equals(itemId))).go();
  }
}`;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans">
      {/* Header */}
      <header className="border-b border-slate-800 bg-slate-900/80 backdrop-blur sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="h-10 w-10 rounded-xl bg-gradient-to-tr from-amber-500 to-indigo-500 flex items-center justify-center shadow-lg shadow-indigo-500/20">
              <Database className="h-5 w-5 text-white" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <span className="font-bold text-lg text-white">MDAD-2026 Schema Audit</span>
                <span className="text-xs bg-emerald-500/20 text-emerald-300 font-mono px-2 py-0.5 rounded border border-emerald-500/30">
                  ตรวจสอบตรงตามบทเรียนสัปดาห์ที่ 8
                </span>
              </div>
              <p className="text-xs text-slate-400">Campus Marketplace • Data Modeling & Offline-first Verification</p>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <button 
              onClick={() => setActiveTab('review')}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition ${
                activeTab === 'review' 
                  ? 'bg-indigo-600 text-white shadow' 
                  : 'text-slate-300 hover:bg-slate-800'
              }`}
            >
              สรุป 4 ข้อประเมิน
            </button>
            <button 
              onClick={() => setActiveTab('code')}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition flex items-center space-x-1.5 ${
                activeTab === 'code' 
                  ? 'bg-indigo-600 text-white shadow' 
                  : 'text-slate-300 hover:bg-slate-800'
              }`}
            >
              <Code2 className="h-4 w-4" />
              <span>โค้ด Drift ที่แก้ไขสมบูรณ์</span>
            </button>
            <button 
              onClick={() => setActiveTab('comparison')}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition flex items-center space-x-1.5 ${
                activeTab === 'comparison' 
                  ? 'bg-indigo-600 text-white shadow' 
                  : 'text-slate-300 hover:bg-slate-800'
              }`}
            >
              <BookOpen className="h-4 w-4" />
              <span>หลักการ Offline-first (ข้อ 8.6)</span>
            </button>
            <button 
              onClick={() => setActiveTab('simulator')}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition flex items-center space-x-1.5 ${
                activeTab === 'simulator' 
                  ? 'bg-indigo-600 text-white shadow' 
                  : 'text-slate-300 hover:bg-slate-800'
              }`}
            >
              <Laptop className="h-4 w-4" />
              <span>จำลอง Unique Constraint</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 space-y-6">

        {/* TAB 1: 4 POINTS AUDIT / REVIEW */}
        {activeTab === 'review' && (
          <div className="space-y-6">
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl">
              <h1 className="text-2xl font-extrabold text-white tracking-tight flex items-center gap-2">
                ผลการตรวจสอบ 4 ข้อคำถามเทียบกับเอกสารการสอนสัปดาห์ที่ 8
              </h1>
              <p className="mt-2 text-slate-300 text-sm leading-relaxed">
                เปรียบเทียบการออกแบบรอบแรก กับแนวทางและมาตรฐานของเอกสารประกอบการสอนวิชา MDAD-2026 (ตอนที่ 2 และตอนที่ 5 หัวข้อ 8.6)
              </p>
            </div>

            {/* 4 Cards Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

              {/* Point 1: Primary Key */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                    <span className="text-xs font-mono font-bold text-slate-400">ประเด็นที่ 1</span>
                    <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/30">
                      <AlertTriangle className="w-3.5 h-3.5" /> ต้องปรับแก้ในตาราง Favorites
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-white mt-3">
                    การกำหนด Primary Key ให้แต่ละตาราง
                  </h3>
                  <div className="mt-3 space-y-2 text-xs text-slate-300">
                    <div className="p-3 bg-slate-950 rounded-xl border border-slate-800/80">
                      <strong className="text-slate-200">ในรอบแรก:</strong> ตาราง Favorites นำ <code className="text-amber-300">productId</code> มาเป็น PK โดยตรง ส่วนตาราง Draft ใช้ Auto-increment
                    </div>
                    <div className="p-3 bg-emerald-950/40 rounded-xl border border-emerald-800/40 text-emerald-200">
                      <strong className="text-emerald-300">ตามบทเรียนหน้า 1:</strong> ทั้งสองตารางต้องมี <code className="text-white font-mono">id: integer().autoIncrement()()</code> เป็น Primary Key (เลขรันของแถวในฐานข้อมูลเอง) เพื่อให้เป็นตัวแทนแถวที่แน่นอน (เปรียบเหมือนเลขบัตรประชาชนของแถว)
                    </div>
                  </div>
                </div>
                <div className="mt-4 pt-3 border-t border-slate-800 text-xs text-slate-400">
                  ✅ <strong>การแก้ไข:</strong> ปรับให้ทั้ง <code className="text-indigo-300">favorite_items</code> และ <code className="text-indigo-300">listing_drafts</code> มี <code className="text-indigo-300">id</code> เป็น Auto-increment PK
                </div>
              </div>

              {/* Point 2: Price Column Type */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                    <span className="text-xs font-mono font-bold text-slate-400">ประเด็นที่ 2</span>
                    <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                      <CheckCircle2 className="w-3.5 h-3.5" /> เลือกถูกต้องตรงตามบทเรียน
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-white mt-3">
                    ชนิดข้อมูลราคาสินค้า (Price Column)
                  </h3>
                  <div className="mt-3 space-y-2 text-xs text-slate-300">
                    <div className="p-3 bg-slate-950 rounded-xl border border-slate-800/80">
                      <strong className="text-slate-200">ชนิดข้อมูลที่เลือก:</strong> <code className="text-emerald-300">{"RealColumn get price => real()();"}</code> ซึ่ง Drift จะสร้าง SQLite type เป็น <code className="text-indigo-300">REAL</code> และสร้าง Dart Model เป็น <code className="text-indigo-300">double</code>
                    </div>
                    <div className="p-3 bg-emerald-950/40 rounded-xl border border-emerald-800/40 text-emerald-200">
                      <strong className="text-emerald-300">ตามบทเรียนหน้า 1:</strong> ระบุชัดเจนว่า ราคาสินค้าควรเป็นตัวเลขทศนิยม (<code className="text-white">Double</code>) ไม่ใช่ String เพื่อให้เรียงลำดับตัวเลขได้ถูกต้อง ไม่ผิดพลาดแบบพจนานุกรม เช่น &quot;9&quot; &gt; &quot;10&quot;
                    </div>
                  </div>
                </div>
                <div className="mt-4 pt-3 border-t border-slate-800 text-xs text-slate-400">
                  ✅ <strong>ผลลัพธ์:</strong> ถูกต้องสมบูรณ์ ไม่ต้องแก้ไขชนิดข้อมูลของราคาสินค้า
                </div>
              </div>

              {/* Point 3: Denormalized Copy vs ItemId only */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                    <span className="text-xs font-mono font-bold text-slate-400">ประเด็นที่ 3</span>
                    <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                      <CheckCircle2 className="w-3.5 h-3.5" /> แนะนำเก็บสำเนา (Offline-first)
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-white mt-3">
                    การเก็บสำเนาข้อมูล (title, price, imageUrl) ใน Favorites
                  </h3>
                  <div className="mt-3 space-y-2 text-xs text-slate-300">
                    <div className="p-3 bg-slate-950 rounded-xl border border-slate-800/80">
                      <strong className="text-slate-200">แนวทางที่เสนอ:</strong> เสนอให้ <strong>เก็บสำเนาข้อมูล (Denormalized Copy)</strong> ได้แก่ ชื่อ ราคา รูปภาพ ไว้ในตาราง Favorites ด้วย ไม่ได้แนะนำให้เก็บแค่ itemId
                    </div>
                    <div className="p-3 bg-emerald-950/40 rounded-xl border border-emerald-800/40 text-emerald-200">
                      <strong className="text-emerald-300">ตรงกับหลักการ Offline-first (หัวข้อ 8.6):</strong> หากเก็บแค่ itemId แล้วต้องยิง API ทุกครั้ง เมื่อผู้ใช้ไม่มีอินเทอร์เน็ต จะเกิด Exception ทันที และหน้า Favorites จะว่างเปล่าไม่สามารถแสดงผลได้
                    </div>
                  </div>
                </div>
                <div className="mt-4 pt-3 border-t border-slate-800 text-xs text-slate-400">
                  ✅ <strong>ผลลัพธ์:</strong> ตรงตามหลักการ Offline-first ของบทเรียนทุกประการ
                </div>
              </div>

              {/* Point 4: .unique() on itemId */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                    <span className="text-xs font-mono font-bold text-slate-400">ประเด็นที่ 4</span>
                    <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/30">
                      <AlertTriangle className="w-3.5 h-3.5" /> ต้องเพิ่ม .unique() ให้กับ itemId
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-white mt-3">
                    ข้อบังคับไม่ให้ค่าซ้ำกัน (.unique()) ในคอลัมน์ itemId
                  </h3>
                  <div className="mt-3 space-y-2 text-xs text-slate-300">
                    <div className="p-3 bg-slate-950 rounded-xl border border-slate-800/80">
                      <strong className="text-slate-200">ในรอบแรก:</strong> ใช้คีย์เดี่ยว productId เป็น PK จึงป้องกันระดับ Table PK แต่ไม่ได้แยกเป็นคอลัมน์ <code className="text-amber-300">itemId</code> พร้อมเมธอด <code className="text-amber-300">.unique()</code>
                    </div>
                    <div className="p-3 bg-emerald-950/40 rounded-xl border border-emerald-800/40 text-emerald-200">
                      <strong className="text-emerald-300">ตามบทเรียนหน้า 1 & 8.6:</strong> เมื่อแยก <code className="text-white">id</code> เป็น Auto-increment แล้ว คอลัมน์ <code className="text-white">itemId</code> ต้องประกาศเป็น <code className="text-emerald-300 font-mono">{"integer().unique()()"}</code>
                    </div>
                  </div>
                </div>
                <div className="mt-4 pt-3 border-t border-slate-800 text-xs text-slate-400">
                  ✅ <strong>การแก้ไข:</strong> กำหนด <code className="text-indigo-300">{"IntColumn get itemId => integer().unique()();"}</code> และใช้ <code className="text-indigo-300">InsertMode.insertOrIgnore</code>
                </div>
              </div>

            </div>
          </div>
        )}

        {/* TAB 2: COMPLETE DART CODE ACCORDING TO LESSON */}
        {activeTab === 'code' && (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                  <FileCode className="h-5 w-5 text-indigo-400" />
                  โค้ด Dart สำหรับ Drift ฉบับปรับปรุงตามบทเรียนสัปดาห์ที่ 8 ครบ 100%
                </h2>
                <p className="text-xs text-slate-400 mt-1">
                  ตรงตามชื่อตาราง <code className="text-indigo-300">FavoriteItems</code> และ <code className="text-indigo-300">ListingDrafts</code> พร้อม <code className="text-emerald-300">.unique()</code> และ Auto-increment PK
                </p>
              </div>
            </div>

            {/* Table Code */}
            <div className="border border-slate-800 rounded-2xl bg-slate-900 overflow-hidden shadow-lg">
              <div className="bg-slate-950/80 px-4 py-3 border-b border-slate-800 flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <span className="w-3 h-3 rounded-full bg-rose-500/80 inline-block"></span>
                  <span className="w-3 h-3 rounded-full bg-amber-500/80 inline-block"></span>
                  <span className="w-3 h-3 rounded-full bg-emerald-500/80 inline-block"></span>
                  <span className="ml-2 font-mono text-xs text-slate-400">lib/data/local/tables.dart (ตรงตามบทเรียนสัปดาห์ที่ 8)</span>
                </div>
                <button
                  onClick={() => copyToClipboard(perfectDartCode, 'tables')}
                  className="flex items-center space-x-1.5 text-xs text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 px-2.5 py-1.5 rounded-lg transition"
                >
                  {copiedId === 'tables' ? (
                    <>
                      <Check className="h-3.5 w-3.5 text-emerald-400" />
                      <span className="text-emerald-400 font-semibold">คัดลอกแล้ว!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="h-3.5 w-3.5" />
                      <span>คัดลอกโค้ด</span>
                    </>
                  )}
                </button>
              </div>
              <pre className="p-4 sm:p-6 text-xs sm:text-sm font-mono text-slate-200 overflow-x-auto leading-relaxed bg-slate-950/40">
                <code>{perfectDartCode}</code>
              </pre>
            </div>

            {/* Repository Code */}
            <div className="border border-slate-800 rounded-2xl bg-slate-900 overflow-hidden shadow-lg">
              <div className="bg-slate-950/80 px-4 py-3 border-b border-slate-800 flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <span className="w-3 h-3 rounded-full bg-rose-500/80 inline-block"></span>
                  <span className="w-3 h-3 rounded-full bg-amber-500/80 inline-block"></span>
                  <span className="w-3 h-3 rounded-full bg-emerald-500/80 inline-block"></span>
                  <span className="ml-2 font-mono text-xs text-slate-400">lib/data/repositories/favorites_repository_drift.dart (หัวข้อ 8.6)</span>
                </div>
                <button
                  onClick={() => copyToClipboard(repositoryCode, 'repo')}
                  className="flex items-center space-x-1.5 text-xs text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 px-2.5 py-1.5 rounded-lg transition"
                >
                  {copiedId === 'repo' ? (
                    <>
                      <Check className="h-3.5 w-3.5 text-emerald-400" />
                      <span className="text-emerald-400 font-semibold">คัดลอกแล้ว!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="h-3.5 w-3.5" />
                      <span>คัดลอกโค้ด</span>
                    </>
                  )}
                </button>
              </div>
              <pre className="p-4 sm:p-6 text-xs sm:text-sm font-mono text-slate-200 overflow-x-auto leading-relaxed bg-slate-950/40">
                <code>{repositoryCode}</code>
              </pre>
            </div>
          </div>
        )}

        {/* TAB 3: OFFLINE-FIRST PHILOSOPHY (SECTION 8.6) */}
        {activeTab === 'comparison' && (
          <div className="space-y-6">
            <div className="bg-gradient-to-r from-blue-950/60 to-slate-900 border border-blue-900/50 rounded-2xl p-6 shadow-xl">
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <BookOpen className="h-5 w-5 text-sky-400" />
                คำอธิบายหลักการ Offline-first ตามบทเรียนหัวข้อ 8.6
              </h2>
              <p className="mt-2 text-slate-300 text-sm leading-relaxed">
                ทำไมการเก็บแค่ <code className="text-amber-300">itemId</code> แล้วไปเรียก API ใหม่ทุกครั้ง จึงล้มเหลวในสถานการณ์ที่ไม่มีอินเทอร์เน็ต
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Bad approach */}
              <div className="bg-slate-900 border border-rose-900/40 rounded-2xl p-6">
                <div className="flex items-center space-x-2 text-rose-400 font-bold text-sm mb-3">
                  <XCircle className="w-5 h-5" />
                  <span>แนวทาง Online-first (เก็บแค่ itemId)</span>
                </div>
                <div className="space-y-3 text-xs text-slate-300">
                  <p>
                    หากตารางในเครื่องเก็บเพียง <code className="text-rose-300">itemId</code> เมื่อเปิดหน้า Favorite Screen แอปจะต้องวนลูปยิง API:
                  </p>
                  <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 font-mono text-rose-300 text-[11px]">
                    {`final res = await http.get('.../items/\$itemId');\nif (res.statusCode != 200) throw Exception();`}
                  </div>
                  <ul className="list-disc list-inside space-y-1.5 text-slate-400">
                    <li><strong className="text-rose-300">ล่มทันทีเมื่อไม่มีเน็ต:</strong> หากนักศึกษาอยู่ในจุดอับสัญญาณ Wi-Fi ของมหาวิทยาลัย หรือเปิดโหมดเครื่องบิน แอปจะติดขัด/หมุนค้างและเกิด Exception ทันที</li>
                    <li><strong className="text-rose-300">หน้าจอว่างเปล่า:</strong> ผู้ใช้ไม่สามารถเปิดดูรายการสินค้าที่ตนเองเคยกดถูกใจไว้ได้เลย ทั้งที่อยู่ในเครื่อง</li>
                    <li><strong className="text-rose-300">กิน Data & แบตเตอรี่:</strong> เปิดหน้าจอกี่ครั้งก็ต้องดาวน์โหลดข้อมูลซ้ำไปซ้ำมา</li>
                  </ul>
                </div>
              </div>

              {/* Good approach */}
              <div className="bg-slate-900 border border-emerald-900/40 rounded-2xl p-6">
                <div className="flex items-center space-x-2 text-emerald-400 font-bold text-sm mb-3">
                  <CheckCircle2 className="w-5 h-5" />
                  <span>แนวทาง Offline-first (เก็บ Denormalized Copy)</span>
                </div>
                <div className="space-y-3 text-xs text-slate-300">
                  <p>
                    เปรียบเหมือน <strong className="text-white">&quot;การจดบันทึกลงในสมุดไดอารี่ก่อนการเขียนลงเอกสารออนไลน์&quot;</strong> ตามอุปมาในบทเรียน:
                  </p>
                  <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 font-mono text-emerald-300 text-[11px]">
                    {`// อ่านเขียนตรงกับ Local DB ทันที โดยไม่มี Network แทรก\nreturn _db.into(_db.favoriteItems).insert(...);`}
                  </div>
                  <ul className="list-disc list-inside space-y-1.5 text-slate-400">
                    <li><strong className="text-emerald-300">Source of Truth อยู่ในเครื่อง:</strong> Local Database เป็นแหล่งข้อมูลหลัก แสดงผลได้ทันทีโดยไม่ต้องรอเน็ต</li>
                    <li><strong className="text-emerald-300">ตัดการพึ่งพา Network ใน Repository:</strong> คลาส <code className="text-slate-200">FavoritesRepositoryDrift</code> ไม่มี import http/dio เลย</li>
                    <li><strong className="text-emerald-300">ยอมเก็บซ้ำเพื่อ UX ที่ดีเยี่ยม:</strong> ยอมเสียพื้นที่ SQLite เล็กน้อยเพื่อแลกกับการเปิดดูสินค้าโปรดและร่าง AI ได้เสี้ยววินาที</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 4: SIMULATOR UNIQUE CONSTRAINT */}
        {activeTab === 'simulator' && (
          <div className="space-y-6">
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
              <div>
                <h2 className="text-lg font-bold text-white flex items-center gap-2">
                  <Laptop className="h-5 w-5 text-indigo-400" />
                  ทดสอบจำลองข้อบังคับ itemId.unique() และ Auto-increment id
                </h2>
                <p className="text-xs text-slate-400">
                  สังเกตคอลัมน์ <code className="text-amber-300">id</code> ที่รันต่ออัตโนมัติ และการป้องกันไม่ให้กดถูกใจ <code className="text-indigo-300">itemId</code> ซ้ำ
                </p>
              </div>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => setSortOrder(prev => prev === 'desc' ? 'asc' : 'desc')}
                  className="flex items-center space-x-1.5 text-xs bg-slate-800 hover:bg-slate-700 text-indigo-300 px-3 py-2 rounded-xl border border-slate-700 transition"
                >
                  <ArrowUpDown className="h-3.5 w-3.5" />
                  <span>เรียงตาม addedAt: {sortOrder === 'desc' ? 'ล่าสุดก่อน (DESC)' : 'เก่าสุดก่อน (ASC)'}</span>
                </button>
              </div>
            </div>

            {duplicateAlert && (
              <div className="bg-rose-950/80 border border-rose-600/60 p-3 rounded-xl text-xs text-rose-200 flex items-center space-x-2 animate-bounce">
                <AlertTriangle className="h-4 w-4 text-rose-400 flex-shrink-0" />
                <span>{duplicateAlert}</span>
              </div>
            )}

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              
              {/* Action Column */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4">
                <h3 className="font-bold text-sm text-white flex items-center gap-2">
                  <PlusCircle className="w-4 h-4 text-emerald-400" />
                  ทดสอบกดถูกใจจากรายการสินค้า
                </h3>
                <p className="text-xs text-slate-400">
                  ลองกดถูกใจสินค้าด้านล่าง ทั้งสินค้าใหม่และสินค้าที่เคยกดแล้ว:
                </p>

                <div className="space-y-2">
                  <button
                    onClick={() => handleAddFavorite(101)}
                    className="w-full text-left p-3 rounded-xl bg-slate-950 hover:bg-slate-800 border border-slate-800 transition flex items-center justify-between"
                  >
                    <div>
                      <div className="text-xs font-semibold text-white">สินค้า itemId: 101</div>
                      <div className="text-[11px] text-amber-400">(เคยกดถูกใจไปแล้ว)</div>
                    </div>
                    <span className="text-xs px-2 py-1 bg-rose-500/20 text-rose-300 rounded border border-rose-500/30">
                      กดซ้ำดูผล
                    </span>
                  </button>

                  <button
                    onClick={() => handleAddFavorite(102)}
                    className="w-full text-left p-3 rounded-xl bg-slate-950 hover:bg-slate-800 border border-slate-800 transition flex items-center justify-between"
                  >
                    <div>
                      <div className="text-xs font-semibold text-white">สินค้า itemId: 102</div>
                      <div className="text-[11px] text-amber-400">(เคยกดถูกใจไปแล้ว)</div>
                    </div>
                    <span className="text-xs px-2 py-1 bg-rose-500/20 text-rose-300 rounded border border-rose-500/30">
                      กดซ้ำดูผล
                    </span>
                  </button>

                  <button
                    onClick={() => handleAddFavorite(205)}
                    className="w-full text-left p-3 rounded-xl bg-slate-950 hover:bg-slate-800 border border-slate-800 transition flex items-center justify-between"
                  >
                    <div>
                      <div className="text-xs font-semibold text-white">สินค้า itemId: 205 (หูฟังเกมมิ่ง)</div>
                      <div className="text-[11px] text-emerald-400">(สินค้าใหม่ ยังไม่เคยกด)</div>
                    </div>
                    <span className="text-xs px-2 py-1 bg-emerald-500/20 text-emerald-300 rounded border border-emerald-500/30">
                      เพิ่มเข้า DB
                    </span>
                  </button>

                  <button
                    onClick={() => handleAddFavorite(309)}
                    className="w-full text-left p-3 rounded-xl bg-slate-950 hover:bg-slate-800 border border-slate-800 transition flex items-center justify-between"
                  >
                    <div>
                      <div className="text-xs font-semibold text-white">สินค้า itemId: 309 (เมาส์ไร้สาย)</div>
                      <div className="text-[11px] text-emerald-400">(สินค้าใหม่ ยังไม่เคยกด)</div>
                    </div>
                    <span className="text-xs px-2 py-1 bg-emerald-500/20 text-emerald-300 rounded border border-emerald-500/30">
                      เพิ่มเข้า DB
                    </span>
                  </button>
                </div>
              </div>

              {/* Data Table */}
              <div className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-2xl p-5 flex flex-col">
                <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                  <div className="flex items-center space-x-2">
                    <Heart className="h-5 w-5 text-rose-500 fill-rose-500" />
                    <h3 className="font-bold text-white text-sm">
                      ตาราง favorite_items ในเครื่อง ({favorites.length} แถว)
                    </h3>
                  </div>
                </div>

                <div className="mt-4 space-y-3 flex-1 overflow-y-auto max-h-[460px]">
                  {sortedFavorites.map((item) => (
                    <div key={item.id} className="p-3 bg-slate-950 border border-slate-800 rounded-xl flex items-center justify-between gap-3">
                      <div className="flex items-center space-x-3 min-w-0">
                        <img 
                          src={item.imageUrl} 
                          alt={item.title} 
                          className="w-12 h-12 object-contain rounded-lg bg-white p-1 flex-shrink-0"
                        />
                        <div className="min-w-0">
                          <div className="flex items-center space-x-2">
                            <span className="text-[10px] font-mono bg-indigo-950 text-indigo-300 px-1.5 py-0.5 rounded border border-indigo-800/40">
                              PK id: #{item.id}
                            </span>
                            <span className="text-[10px] font-mono bg-amber-950 text-amber-300 px-1.5 py-0.5 rounded border border-amber-800/40">
                              itemId: {item.itemId} (Unique)
                            </span>
                            <span className="text-xs font-bold text-emerald-400">
                              \${item.price}
                            </span>
                          </div>
                          <h4 className="text-xs font-medium text-white truncate mt-1">
                            {item.title}
                          </h4>
                          <div className="text-[10px] text-slate-500 mt-0.5">
                            addedAt: {item.addedAt}
                          </div>
                        </div>
                      </div>
                      <button
                        onClick={() => setFavorites(favorites.filter(f => f.id !== item.id))}
                        className="text-slate-500 hover:text-rose-400 p-1.5 rounded-lg transition"
                        title="ลบแถวนี้"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>

            </div>
          </div>
        )}

      </main>

      <footer className="border-t border-slate-800/80 bg-slate-950 py-4 text-center text-xs text-slate-500">
        Campus Marketplace • MDAD-2026 Week 8 Schema Specification
      </footer>
    </div>
  );
}


```


### ขั้นตอนที่ 1.2: ตรวจสอบและเทียบกับหลักการในบทเรียน 🧠 คิดเอง

เปรียบเทียบ Schema ที่ได้จาก Gemini กับหลักการในบทเรียนหัวข้อ 8.3 แล้วตอบคำถามต่อไปนี้ โดยการสรุปตามความเข้าใจของตนเอง (ห้ามคัดลอกคำตอบจาก Gemini มาวางตรง ๆ)

- Gemini กำหนด Primary Key ให้แต่ละตารางถูกต้องหรือไม่ (ควรเป็น Auto-increment Integer ตามที่อธิบายในบทเรียน)
- คอลัมน์ราคาสินค้า Gemini เลือกชนิดข้อมูลใด ตรงกับที่บทเรียนแนะนำ (`RealColumn`/`double`) หรือไม่ หากไม่ตรง ให้แก้ไขเอง
- Gemini เสนอให้เก็บสำเนาข้อมูล (เช่น ชื่อ/ราคาสินค้า) ซ้ำไว้ในตาราง Favorites หรือแนะนำให้เก็บแค่ `itemId` แล้วไปเรียก API ใหม่ทุกครั้ง หากแนะนำแบบหลัง ให้อธิบายตามหลักการ Offline-first ในบทหนังสือเรียนหัวข้อ 8.6 ว่าทำไมแนวทางนั้นไม่เหมาะกับสถานการณ์ที่ไม่มีอินเทอร์เน็ต
- Gemini กำหนดให้คอลัมน์ที่อ้างอิงสินค้า (`itemId`) ห้ามมีค่าซ้ำกัน (`.unique()`) หรือไม่ ถ้าไม่ได้กำหนด ให้เพิ่มเอง เพราะถ้าไม่มีข้อบังคับนี้ ผู้ใช้กดหัวใจสินค้าชิ้นเดียวกันซ้ำได้ไม่จำกัด ทำให้ตาราง Favorites มีแถวซ้ำกันสะสมไปเรื่อย ๆ

> ✅ **Checkpoint 1.1** บันทึกคำตอบจากคำถามด้านบนทั้ง 4 ข้อ พร้อมแนบภาพหน้าจอผลลัพธ์จาก Gemini
<img width="1347" height="617" alt="image" src="https://github.com/user-attachments/assets/54a101eb-2efb-4a9a-a630-5dd856d5ae5e" />

```text

- Gemini กำหนด Primary Key ให้แต่ละตารางถูกต้องหรือไม่ (ควรเป็น Auto-increment Integer ตามที่อธิบายในบทเรียน)
      - กำหนดให้เป็นตัวเลขรันอัตโนมัติ (Auto-increment) ทั้งสองตารางเลย (IntColumn get id => integer().autoIncrement()();)  
- คอลัมน์ราคาสินค้า Gemini เลือกชนิดข้อมูลใด ตรงกับที่บทเรียนแนะนำ (`RealColumn`/`double`) หรือไม่ หากไม่ตรง ให้แก้ไขเอง
         - เลือกใช้ RealColumn (price => real()();)
- Gemini เสนอให้เก็บสำเนาข้อมูล (เช่น ชื่อ/ราคาสินค้า) ซ้ำไว้ในตาราง Favorites หรือแนะนำให้เก็บแค่ `itemId` แล้วไปเรียก API ใหม่ทุกครั้ง หากแนะนำแบบหลัง ให้อธิบายตามหลักการ Offline-first ในบทหนังสือเรียนหัวข้อ 8.6 ว่าทำไมแนวทางนั้นไม่เหมาะกับสถานการณ์ที่ไม่มีอินเทอร์เน็ต
      - โค้ดเลือกที่จะก็อปปี้รายละเอียดสำคัญ ๆ อย่าง ชื่อ รูป และราคา เก็บลงตารางในเครื่องไว้ด้วยเลย (title, imageUrl, price)
- Gemini กำหนดให้คอลัมน์ที่อ้างอิงสินค้า (`itemId`) ห้ามมีค่าซ้ำกัน (`.unique()`) หรือไม่ ถ้าไม่ได้กำหนด ให้เพิ่มเอง เพราะถ้าไม่มีข้อบังคับนี้ ผู้ใช้กดหัวใจสินค้าชิ้นเดียวกันซ้ำได้ไม่จำกัด ทำให้ตาราง Favorites มีแถวซ้ำกันสะสมไปเรื่อย ๆ
   - ใส่ .unique() ป้องกันไว้ตรงรหัสสินค้า (IntColumn get itemId => integer().unique()();) เอาไว้ดักทางเวลากดหัวใจซ้ำๆ ข้อมูลมันจะได้ไม่เบิ้ลแถวไปเรื่อยๆ
```

---

## ส่วนที่ 2: ติดตั้ง Drift และประกาศตาราง

### ขั้นตอนที่ 2.1: ติดตั้งแพ็กเกจ 🔧 ทำตามขั้นตอน

เพิ่ม dependency ในไฟล์ `pubspec.yaml` ของโปรเจกต์ `campus_marketplace_w7` **ต่อจาก** `http`, `provider` และ `image_picker` ที่มีอยู่แล้วจากสัปดาห์ที่ 6-7 (ไม่ต้องลบของเดิม)

```yaml
dependencies:
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.20.0
  build_runner: ^2.4.13
```

รัน `flutter pub get` ในเทอร์มินัล

### ขั้นตอนที่ 2.2: สร้างไฟล์ประกาศตาราง 🔧 ทำตามขั้นตอน

สร้างไฟล์ `lib/database/tables.dart` ตามโครงสร้างในบทเรียนหัวข้อ 8.4 (ใช้ Schema ตามบทเรียน เพื่อให้ตรงกับใบงานการทดลองในส่วนถัดไป )

```dart
import 'package:drift/drift.dart';

class FavoriteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().unique()(); // .unique() ป้องกันถูกใจสินค้าชิ้นเดียวกันซ้ำ
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ListingDraftRow') // ตั้งชื่อ Class ที่ Generate เอง ดูคำอธิบายด้านล่าง
class ListingDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get description => text()();
  TextColumn get imagePath => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

⚠️ **จุดที่พลาดง่ายมากในสัปดาห์นี้โดยเฉพาะ**: ปกติ Drift จะตั้งชื่อ Class ที่ Generate จากตารางด้วยการตัด `s` ท้ายชื่อ Table ออก (เช่นตาราง `FavoriteItems` → Class `FavoriteItem` ตามที่เรียนในบทหนังสือเรียน) ถ้าปล่อยให้ `ListingDrafts` ทำแบบเดียวกัน Drift จะสร้าง Class ชื่อ `ListingDraft` ออกมา ซึ่ง**ชนกับ Class `ListingDraft` ที่สร้างไว้แล้วตั้งแต่ใบงานการทดลองที่ 7** (เก็บแค่ `title`/`category`/`description` ที่ได้จาก AI ก่อนบันทึก) ทำให้โปรเจกต์มี 2 Class ชื่อเดียวกันคนละความหมายและคอมไพล์ไม่ผ่านเพราะ import ชนกัน Annotation `@DataClassName('ListingDraftRow')` ด้านบนแก้ปัญหานี้โดยสั่งให้ Driftตั้งชื่อ Class ที่ Generate เป็น `ListingDraftRow` แทน 


---

## ส่วนที่ 3: สร้างคลาสฐานข้อมูลหลักและรัน Code Generation

### ขั้นตอนที่ 3.1: สร้าง AppDatabase 🔧 ทำตามขั้นตอน

ดูตัวอย่างโค้ดเต็มในบทเรียนหัวข้อ 8.4 ขั้นตอนที่ 3 แล้วคัดลอกมาสร้างไฟล์ `lib/database/app_database.dart` ของตนเอง (import ตารางจาก `tables.dart` ที่สร้างในส่วนที่ 2 เข้ามาใช้งาน พร้อม `@DriftDatabase(tables: [FavoriteItems, ListingDrafts])`) หากตั้งชื่อ Class ของตารางต่างจากตัวอย่าง ให้แก้ชื่อใน `@DriftDatabase(tables: [...])` ให้ตรงกับชื่อจริงใน `tables.dart` ของตนเองด้วย

```
🔧 CRUD Operations ผ่าน Repository Pattern (ไม่เรียก AppDatabase ตรง ๆ)
Widget ต้องไม่เรียก AppDatabase ตรง ๆ เด็ดขาด เช่นเดียวกับหลัก Repository Pattern ที่วางไว้ตั้งแต่สัปดาห์ที่ 6 (ItemRepository/ItemRepositoryApi) จึงต้องสร้าง Interface (FavoritesRepository) คู่กับ Implementation (FavoritesRepositoryDrift) ตั้งแต่ตอนเขียน CRUD ครั้งแรกนี้เลย

 
 
 
favorites_repository_drift.dart
// Interface: ระบุว่า Widget "ทำอะไรได้บ้าง" โดยไม่ระบุว่า "ทำอย่างไร"
abstract class FavoritesRepository {
  Future<void> addFavorite(int itemId, String title, double price, String imageUrl);
  Future<List<FavoriteItem>> getAllFavorites();
  Future<void> removeFavorite(int itemId);
}

// Implementation: รู้รายละเอียดว่าใช้ Drift เก็บข้อมูลจริง
class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;
  FavoritesRepositoryDrift(this._db); // รับ AppDatabase ทาง Constructor (DI)

  // Create: เพิ่มสินค้าลงรายการถูกใจ
  @override
  Future<void> addFavorite(int itemId, String title, double price, String imageUrl) {
    return _db.into(_db.favoriteItems).insert( // .into() ระบุตารางปลายทาง
      FavoriteItemsCompanion.insert( // Companion สร้างแถวใหม่โดยไม่ต้องระบุ id/addedAt
        itemId: itemId, title: title, price: price, imageUrl: imageUrl,
      ),
      mode: InsertMode.insertOrIgnore, // itemId ซ้ำ (ผิดกฎ .unique()) ให้ข้ามเงียบๆ แทนที่จะโยน Exception
    );
  }

  // Read: อ่านรายการถูกใจทั้งหมด เรียงจากล่าสุดไปเก่าสุด
  @override
  Future<List<FavoriteItem>> getAllFavorites() {
    return (_db.select(_db.favoriteItems) // เริ่ม Query จากตาราง favoriteItems
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)])) // เรียงล่าสุดก่อน
        .get(); // สั่งให้ Query ทำงานจริงและคืนผลลัพธ์
  }

  // Delete: เอาสินค้าออกจากรายการถูกใจด้วย itemId
  @override
  Future<void> removeFavorite(int itemId) {
    return (_db.delete(_db.favoriteItems)
          ..where((t) => t.itemId.equals(itemId))) // ลบเฉพาะแถวที่ itemId ตรงกัน
        .go(); // .go() ใช้กับคำสั่งที่เปลี่ยนแปลงข้อมูล
  }
}
// ผลลัพธ์: Widget เห็นแค่ FavoritesRepository (Interface) เท่านั้น ไม่รู้จัก AppDatabase เลย
implements FavoritesRepository บังคับให้ FavoritesRepositoryDrift ต้องเขียนเมธอดครบทุกตัวที่ Interface ประกาศไว้ มิเช่นนั้น Dart จะฟ้อง Error ตั้งแต่ตอนคอมไพล์ ส่วน _db.into(_db.favoriteItems).insert(...) รับพารามิเตอร์เป็น FavoriteItemsCompanion ซึ่งเป็น Class พิเศษที่ Drift สร้างให้คู่กับทุกตาราง ใช้ตอนเพิ่ม/แก้ไขข้อมูลบางส่วน (ต่างจาก FavoriteItem เปล่า ๆ ที่ใช้ตอนอ่านข้อมูลครบทุกคอลัมน์) รายละเอียดทั้งหมดนี้ถูกซ่อนไว้ภายใน Implementation ผู้เรียกใช้ผ่าน Interface ไม่จำเป็นต้องรู้จักเลยด้วยซ้ำ

mode: InsertMode.insertOrIgnore จำเป็นเพราะคอลัมน์ itemId เป็น .unique() ถ้าไม่ใส่ (ปล่อยให้ใช้ค่าเริ่มต้น InsertMode.insertOrAbort) การ Insert itemId ที่มีอยู่แล้วจะทำให้ Drift โยน Exception UNIQUE constraint failed ทันที การใช้ insertOrIgnore แทนบอกว่า "ถ้าซ้ำ ให้ข้ามเงียบ ๆ" ซึ่งเหมาะกับปุ่มกดถูกใจ เพราะกดซ้ำไม่ควรทำให้แอป Error

เครื่องหมาย .. คือ Cascade Operator ของ Dart ใช้เรียกเมธอดต่อจากอ็อบเจกต์เดิมได้หลายเมธอดโดยไม่ต้องพิมพ์ชื่อตัวแปรซ้ำ ปิดท้ายด้วย .get() เมื่อเป็นการอ่าน และ .go() เมื่อเป็นการเปลี่ยนแปลงข้อมูล (Insert/Update/Delete)
```
### ขั้นตอนที่ 3.2: รัน Code Generation 🔧 ทำตามขั้นตอน

รันคำสั่งต่อไปนี้ในเทอร์มินัลของ VS Code ที่โฟลเดอร์โปรเจกต์

```bash
dart run build_runner build --delete-conflicting-outputs
```

รอจนกระบวนการเสร็จสิ้น ตรวจสอบว่ามีไฟล์ `lib/database/app_database.g.dart` ถูกสร้างขึ้นใหม่ และตรวจสอบใน Debug Console ว่าไม่มี Error เรื่อง Class ชื่อซ้ำ (ถ้าเจอ ให้กลับไปตรวจสอบ ขั้นตอน 2.2 ว่าใส่ `@DataClassName` ไว้ถูกต้องหรือไม่)

### ขั้นตอนที่ 3.3: เชื่อม AppDatabase เข้ากับแอป 🧠 คิดเอง (มีโครงให้)
**นักศึกษาเขียน Code เอง**

สัปดาห์นี้ซับซ้อนกว่าเดิมเล็กน้อย เพราะ `main.dart` ต้องสร้าง `AppDatabase` ขึ้นมาหนึ่งอินสแตนซ์ แล้วส่งต่อให้ Repository **สองตัว** (Favorites และ Draft) ที่จะสร้างในส่วนที่ 4-5 ก่อนส่งเข้า `MainScaffold` อีกที ตรวจสอบตามโครงนี้แล้วเติมส่วนที่ยังไม่มี (Repository ทั้งสองตัวจะสร้างจริงในส่วนถัดไป ตอนนี้แค่เตรียมจุดเชื่อมไว้ก่อน)

```
ในฟังก์ชัน main():
    สร้าง AppDatabase() ขึ้นมา 1 ตัว เก็บไว้ในตัวแปร db

    เรียก runApp() ห่อด้วย ChangeNotifierProvider<CartModel> เหมือนเดิม
    ส่ง db เข้าไปเป็นพารามิเตอร์ของ MyApp (เพิ่ม field ใหม่ใน MyApp รับค่า AppDatabase)

ใน MyApp.build(context):
    สร้าง MainScaffold โดยส่งพารามิเตอร์ 3 ตัวเข้าไป:
        itemRepository: ItemRepositoryApi() (ตัวเดิมจากสัปดาห์ที่ 6-7)
        favoritesRepository: สร้างจาก AppDatabase ที่รับมา (จะเขียน Class จริงในส่วนที่ 4)
        draftRepository: สร้างจาก AppDatabase ตัวเดียวกัน (จะเขียน Class จริงในส่วนที่ 5)
```

> 💡 สังเกตว่า `AppDatabase` ถูกสร้างขึ้น **ครั้งเดียว** ใน `main()` แล้วส่งต่อผ่าน Constructor ไปเรื่อย ๆ (Dependency Injection) หลักการเดียวกับที่ `ItemRepositoryApi()` ถูกสร้างครั้งเดียวแล้วส่งต่อมาตั้งแต่สัปดาห์ที่ 6 — ห้ามสร้าง `AppDatabase()` ใหม่หลายจุดในแอปเดียวกัน เพราะแต่ละอินสแตนซ์จะเปิดการเชื่อมต่อไฟล์ฐานข้อมูลแยกจากกัน ทำให้ข้อมูลที่เขียนจากจุดหนึ่งอาจไม่ปรากฏอีกจุดหนึ่ง

> ✅ **Checkpoint 3.1**

capture หน้าจอผลลัพธ์คำสั่ง `dart run build_runner build` จากขั้นตอนที่ 3.2 ที่แสดงว่าสร้างไฟล์สำเร็จ (ไม่มี Error เรื่อง Class ชื่อซ้ำ) จากนั้นเปิดไฟล์ main.dart ที่แก้ตามขั้นตอนที่ 3.3 โดย ยังไม่ต้องรันแอปในจุดนี้ เพราะ VS Code จะขีดเส้นสีแดงใต้ FavoritesRepositoryDrift และ ListingDraftRepositoryDrift (ยังไม่มี Class จริง จะเขียน Class นี้ในส่วนที่ 4-5) และถ้าสั่งรันตอนนี้แอปจะ Error ทันทีเพราะคอมไพล์ไม่ผ่าน ถือเป็นเรื่องปกติ — จะกลับมารันแอปได้จริงอีกครั้งหลังทำ Checkpoint 4.1 และ 5.1 เสร็จ

```text
PS C:\work-2026-1\campus_marketplace_w7> dart run build_runner build
10s drift_dev on 60 inputs: 54 skipped, 2 output, 2 same, 2 no-op; spent 8s analyzing, 2s resolving                                 
0s source_gen:combining_builder on 30 inputs: 30 skipped                                                                            
                                                                                                                                    
Built with build_runner/aot in 15s; wrote 4 outputs.   
```
<img width="575" height="332" alt="image" src="https://github.com/user-attachments/assets/ef6b0f36-c9ae-483a-bd68-8e197250e65d" />

---

## ส่วนที่ 4: สร้างฟีเจอร์ "รายการโปรด" (Favorites) ตั้งแต่ต้น

นี่คือฟีเจอร์ใหม่ทั้งหมดของแอป ประกอบด้วย 4 ส่วนที่ต้องทำให้ครบ คือ 1.Repository 2.ปุ่มกดถูกใจในหน้า Home 3.หน้าจอแสดงรายการโปรด และ 4.การเพิ่ม Tab ที่ 3 เข้า Bottom Navigation Bar

### ขั้นตอนที่ 4.1: สร้าง Repository Interface และ Implementation 
**นักศึกษาเขียน Code เอง**

สร้างไฟล์ `lib/repositories/favorites_repository.dart` (Interface) และ `lib/repositories/favorites_repository_drift.dart` (Implementation) เองทั้งหมด โดยอ้างอิงโครงสร้างและลำดับขั้นตอนจากบทเรียนหัวข้อ 8.4 (ซึ่งสอนตัวอย่างนี้ไว้แบบเต็มทุกบรรทัดอยู่แล้ว) สังเกตว่ารูปแบบนี้เหมือนกับ `ItemRepository`/`ItemRepositoryApi` ในสัปดาห์ที่ 6 ทุกประการ เพียงแค่เปลี่ยนจากการเรียก REST API มาเป็นการเรียก Drift แทน


**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- Interface `FavoritesRepository` ต้องมีอย่างน้อย 3 เมธอด: `addFavorite(int itemId, String title, double price, String imageUrl)`, `getAllFavorites()` (คืนค่า `Future<List<FavoriteItem>>` เรียงจากกดถูกใจล่าสุด), `removeFavorite(int itemId)`
- Class `FavoritesRepositoryDrift implements FavoritesRepository` ต้องรับ `AppDatabase` เข้ามาทาง Constructor (เหมือน `final AppDatabase _db;`)
- ทุกเมธอดต้องเขียนลง/อ่านจาก `_db.favoriteItems` เท่านั้น ห้ามมีโค้ดเรียก `http`/Dio ปะปนอยู่เลย (ตามหลักการ Offline-first หัวข้อ 8.6)
- `getAllFavorites()` ต้องเรียงผลลัพธ์ด้วย `orderBy` ตามคอลัมน์ `addedAt` จากใหม่ไปเก่า
- `addFavorite(...)` ต้องเรียก `.insert(...)` พร้อมระบุ `mode: InsertMode.insertOrIgnore` เพราะคอลัมน์ `itemId` เป็น `.unique()` (Checkpoint 2.1) ถ้าไม่ใส่ การกดหัวใจซ้ำที่สินค้าชิ้นเดิมจะทำให้แอป Error ด้วย `UNIQUE constraint failed` แทนที่จะแค่ไม่มีอะไรเกิดขึ้น

### ขั้นตอนที่ 4.2: เพิ่มปุ่ม "กดถูกใจ" ในหน้า Home 🧠 คิดเอง (มีโครงให้)

แก้ไข `lib/screens/home_page.dart` ให้รับ `FavoritesRepository` เข้ามาทาง Constructor เพิ่มอีก 1 ตัว (คู่กับ `ItemRepository` ที่มีอยู่แล้ว) แล้วเพิ่มไอคอนรูปหัวใจต่อท้ายแต่ละแถวสินค้าใน `ListTile` คู่กับไอคอนตะกร้าที่มีอยู่แล้ว

**แนวทางเขียนโค้ด (Pseudocode)** — ลองไล่ตามลำดับนี้แล้วแปลงเป็น Dart ด้วยตัวเอง

```
ใน HomePage (StatefulWidget):
    เพิ่ม field favoritesRepository ชนิด FavoritesRepository ใน Constructor

ใน trailing ของแต่ละ ListTile (ปัจจุบันมีแค่ปุ่มตะกร้า):
    เปลี่ยนจาก IconButton เดี่ยว เป็น Row ที่มี mainAxisSize: MainAxisSize.min แล้วใส่ 2 ปุ่ม:
        ปุ่มที่ 1: ไอคอนรูปหัวใจ (Icons.favorite_border)
            เมื่อกด → เรียก widget.favoritesRepository.addFavorite(item.id, item.title, item.price, item.imageUrl)
            เนื่องจากเป็น Future ต้องจัดการ error ด้วย try/catch หรือ .catchError() แล้วแสดง SnackBar แจ้งผล (สำเร็จ/ผิดพลาด)
        ปุ่มที่ 2: ปุ่มตะกร้าเดิม (ไม่ต้องแก้ไข)
```

**คำใบ้ / จุดที่ต้องระวัง**

- `addFavorite(...)` เป็น `Future<void>` ดังนั้นฟังก์ชันที่เรียกมันใน `onPressed` ควรเป็น `async` เพื่อ `await` และจับ error ได้ถูกต้อง
- ไม่ต้องเปลี่ยนไอคอนหัวใจให้ทึบ (Toggle สถานะ) ในสัปดาห์นี้ — แค่กดแล้วเพิ่มลงฐานข้อมูลสำเร็จพร้อม SnackBar ยืนยันก็เพียงพอ (การเอาออกจากรายการโปรดทำที่หน้า Favorites โดยเฉพาะในขั้นตอนถัดไป เหมือนกับที่การลบออกจากตะกร้าทำที่หน้า Checkout ไม่ใช่หน้า Home)
- อย่าลืมแก้จุดที่สร้าง `HomePage(...)` ใน `MainScaffold` (ขั้นตอนที่ 4.4) ให้ส่ง `favoritesRepository` เข้าไปด้วย ไม่งั้นจะ Error ว่าพารามิเตอร์ที่จำเป็นหายไป

### ขั้นตอนที่ 4.3: สร้างหน้าจอ "รายการโปรด" (FavoritesPage) 
**นักศึกษาเขียน Code เอง**
สร้างไฟล์ `lib/screens/favorites_page.dart` เป็น `StatefulWidget` ที่รับ `FavoritesRepository` เข้ามาทาง Constructor

**ข้อกำหนดที่ต้องมีครบ:**

- ใช้ `FutureBuilder` เรียก `repository.getAllFavorites()` ใน `initState()` (รูปแบบเดียวกับ `HomePage` ที่เรียก `repository.getItems()` มาตั้งแต่สัปดาห์ที่ 6)
- จัดการ 3 สถานะให้ครบ: กำลังโหลด (`CircularProgressIndicator`), รายการว่างเปล่า (ข้อความแนะนำ เช่น "ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ"), และมีข้อมูล (`ListView.builder` แสดง title/price/imageUrl)
- แต่ละแถวมีปุ่มลบ (`IconButton` ไอคอนถังขยะ) ที่เรียก `repository.removeFavorite(itemId)` แล้ว `setState()` เพื่อโหลดรายการใหม่ (เรียก `getAllFavorites()` ซ้ำแล้วอัปเดต Future ที่ผูกกับ `FutureBuilder`)
- ไม่ต้องรับ `ItemRepository` เข้ามาในหน้านี้ เพราะข้อมูลที่แสดง (title/price/imageUrl) ถูกเก็บสำเนาไว้ในตาราง `FavoriteItems` ครบอยู่แล้วตามที่ออกแบบไว้ในส่วนที่ 1 — ไม่ต้องเรียก Fake Store API ซ้ำ

### ขั้นตอนที่ 4.4: เพิ่ม Tab ที่ 3 เข้า MainScaffold ที่มีอยู่แล้ว 🔧 ทำตามขั้นตอน

ตามที่ `campus_marketplace_lab_roadmap.md` หัวข้อ 2.1 วางแผนไว้ Favorites คือ Tab ที่ 3 ของแอป เปิดไฟล์ `lib/screens/main_scaffold.dart` ที่สร้างไว้แล้วตั้งแต่สัปดาห์ที่ 7 แล้วแก้ไขตามนี้ **ไม่ต้องแก้ไขโค้ดภายใน `HomePage` หรือ `SellItemPage` เพิ่มเติมจากที่ทำในขั้นตอนก่อนหน้านี้**

```dart
// ก่อนแก้
class MainScaffold extends StatefulWidget {
  final ItemRepository repository;
  const MainScaffold({super.key, required this.repository});
  // ...
}
```

```dart
// หลังแก้
class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository; // จะมีจริงหลังทำส่วนที่ 5 เสร็จ
  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });
  // ...
}
```

และในเมธอด `build`

```dart
// ก่อนแก้
final pages = [
  HomePage(repository: widget.repository),
  const SellItemPage(),
];
// ...
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
  BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
],
```

```dart
// หลังแก้
final pages = [
  HomePage(
    repository: widget.itemRepository,
    favoritesRepository: widget.favoritesRepository,
  ),
  SellItemPage(draftRepository: widget.draftRepository),
  FavoritesPage(repository: widget.favoritesRepository),
];
// ...
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
  BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
  BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
],
```

อย่าลืมเพิ่ม `import 'favorites_page.dart';`, `import '../repositories/favorites_repository.dart';` และ `import '../repositories/listing_draft_repository.dart';` ที่หัวไฟล์ และแก้ `lib/main.dart` ให้ส่งพารามิเตอร์ตามชื่อใหม่ (`itemRepository:`, `favoritesRepository:`, `draftRepository:`) ตามโครงที่วางไว้ในขั้นตอนที่ 3.3

> ⚠️ `IndexedStack` อ้างอิง index ตามตำแหน่งใน List `pages` และ `BottomNavigationBarItem` ต้องมีจำนวนเท่ากับ `pages` เสมอ (ตอนนี้ต้องเป็น 3 ทั้งคู่) ถ้าจำนวนไม่ตรงกันแอปจะ Error ทันทีตอนรัน ไม่ใช่แค่แสดงผลผิด

> ✅ **Checkpoint 4.1** รันแอปแล้วทดสอบ: (ก) กดหัวใจที่สินค้า 3 ชิ้นจากหน้า Home (ข) สลับไป Tab "รายการโปรด" เห็นครบทั้ง 3 ชิ้น (ค) ปิดแอปให้สนิท (Force Stop หรือปัดออกจาก Recent Apps) แล้วเปิดใหม่ กลับไปที่ Tab รายการโปรดอีกครั้ง ถ่ายภาพหน้าจอ (ข) และ (ค) เทียบกัน ต้องแสดงรายการเดิมครบทุกชิ้น พร้อมทดสอบกดลบ (Remove) 1 ชิ้น แล้วปิดเปิดแอปใหม่อีกครั้งเพื่อยืนยันว่าการลบก็ถูกบันทึกถาวรเช่นกัน (ง) กลับไปหน้า Home แล้วกดหัวใจซ้ำที่สินค้าชิ้นเดิมอีกครั้ง (ชิ้นที่ยังไม่ได้ลบ) แล้วตรวจสอบที่ Tab รายการโปรดว่ายังแสดงสินค้าชิ้นนั้นแค่แถวเดียว ไม่ซ้ำเป็น 2 แถว และแอปไม่ Error
# ก
<img width="1080" height="2400" alt="Screenshot_20261006_162016 (1)" src="https://github.com/user-attachments/assets/e76a41e2-e622-41d3-983e-9e6c7cd8c581" />
# ข
<img width="1080" height="2400" alt="Screenshot_20261006_203757 (1)" src="https://github.com/user-attachments/assets/9509be51-fefe-47b2-8b5b-4ac1f3e9d6a6" />
<img width="1080" height="2400" alt="Screenshot_20261006_162009 (1)" src="https://github.com/user-attachments/assets/c9e92544-d95f-49cf-a56e-05d69d49dfb0" />

# ค
<img width="1080" height="2400" alt="Screenshot_20261006_204314" src="https://github.com/user-attachments/assets/f0d0effe-12b4-4002-9406-54389babfd69" />
<img width="1080" height="2400" alt="Screenshot_20261006_203827 (1)" src="https://github.com/user-attachments/assets/d56563d1-f16b-47b5-9837-e93dd84829ee" />

# ง
<img width="1080" height="2400" alt="Screenshot_20261006_204430" src="https://github.com/user-attachments/assets/52e784e4-ddca-406f-a552-11ab7a704ac4" />
<img width="1080" height="2400" alt="Screenshot_20261006_204426" src="https://github.com/user-attachments/assets/6aa8198c-7372-4e37-8a94-b18c4cf1e3f6" />

---

## ส่วนที่ 5: นำร่างประกาศขายสินค้า (สัปดาห์ที่ 7) มาบันทึกถาวร

### ขั้นตอนที่ 5.1: สร้าง Repository สำหรับ Draft 
**นักศึกษาเขียน Code เอง**

สร้างไฟล์ `lib/repositories/listing_draft_repository.dart` (Interface) และ `lib/repositories/listing_draft_repository_drift.dart` (Implementation) ในรูปแบบเดียวกับส่วนที่ 4 ทุกประการ แต่ทำงานกับตาราง `ListingDrafts` แทน

**ข้อกำหนดที่ต้องมีครบ:**

- Interface `ListingDraftRepository` ต้องมีอย่างน้อย 3 เมธอด: `saveDraft(ListingDraft draft, String imagePath)` (บันทึกร่างใหม่ — รับ `ListingDraft` ที่มีอยู่แล้วจากสัปดาห์ 7 บวก path รูปภาพแยกต่างหาก เพราะ `ListingDraft` เดิมไม่มี field นี้), `getAllDrafts()` (คืนค่า `Future<List<ListingDraftRow>>` เรียงจากแก้ไขล่าสุด — สังเกตว่าใช้ `ListingDraftRow` ไม่ใช่ `ListingDraft` ตามที่อธิบายไว้ใน Checkpoint 2.1), และ `deleteDraft(int id)`
- `saveDraft(...)` ต้องดึงค่า `draft.title`, `draft.category`, `draft.description` มาประกอบกับ `imagePath` ที่รับมาแยก แล้วสร้าง `ListingDraftsCompanion.insert(...)` ก่อน `.insert()` ลงฐานข้อมูล

### ขั้นตอนที่ 5.2: แก้ไขหน้า "ลงประกาศขายสินค้า" ให้บันทึกร่างถาวร 🔧 ทำตามขั้นตอน 

เปิดไฟล์ `sell_item_page.dart` จากสัปดาห์ที่ 7 แก้ไข 2 จุด: (1) รับ `ListingDraftRepository` เข้ามาทาง Constructor และ (2) แก้ปุ่ม "ยืนยันร่างประกาศ" (ที่เดิมแค่เก็บค่าไว้ใน State ชั่วคราวตามใบงานสัปดาห์ที่ 7 ส่วนที่ 5.2)

```dart
// ก่อนแก้
class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});
  // ...
}
```

```dart
// หลังแก้
class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  const SellItemPage({super.key, required this.draftRepository});
  // ...
}
```

และในปุ่ม "ยืนยันร่างประกาศ" เปลี่ยนจากการเก็บค่าไว้ในตัวแปร State เฉย ๆ ให้เรียก `await widget.draftRepository.saveDraft(draft, imageFile!.path)` แทน จัดการ Loading/Success/Error ระหว่างบันทึกเช่นเดียวกับที่เคยทำตอนเรียก Gemini Vision ในสัปดาห์ที่ 7 แล้วค่อยแสดง `SnackBar` ยืนยันและล้างฟอร์มเหมือนเดิมหลังบันทึกสำเร็จ

### ขั้นตอนที่ 5.3: สร้างหน้าจอ "ร่างประกาศของฉัน" (My Drafts) 
**นักศึกษาเขียน Code เอง**

สร้างหน้าจอใหม่ `lib/screens/my_drafts_page.dart` ที่รับ `ListingDraftRepository` เข้ามาทางConstructor เรียก `repository.getAllDrafts()` แสดงรายการร่างทั้งหมดที่เคยบันทึกไว้เป็น `ListView` (รูปแบบเดียวกับ `FavoritesPage` ในส่วนที่ 4.3) แต่ละรายการแสดงชื่อประกาศ หมวดหมู่ และวันเวลาที่แก้ไขล่าสุด พร้อมปุ่มลบร่างที่ไม่ต้องการแล้ว จัดการสถานะ Loading/Success/Empty ให้ครบ

**ทำไมหน้านี้ไม่ใช่ Tab ที่ 4**: ตาม `campus_marketplace_lab_roadmap.md` หัวข้อ 2.1 มีกฎชัดเจนว่าอะไรควรเป็น Tab (ปลายทางหลักที่สลับไปมาตลอดเวลา) กับอะไรควรเป็น Push/Pop (Flow เฉพาะกิจที่มีจุดเริ่ม-จบ) "ร่างประกาศของฉัน" เป็นหน้าจัดการร่างที่ผูกกับ Flow การลงประกาศโดยตรง ไม่ใช่ปลายทางหลักที่ผู้ใช้เปิดดูตลอดเวลาเหมือน Favorites อีกทั้ง Roadmap ได้กำหนดไว้แล้วว่า Tab ที่ 4 ของแอปคือ "โปรไฟล์" ในสัปดาห์หน้า การเพิ่ม Tab ใหม่อีกตัวตอนนี้จะทำให้ลำดับ Tab ทั้งเทอมเพี้ยนไปจากแผน **จึงให้เข้าถึงหน้านี้ด้วยปุ่มไอคอนใน AppBar ของ Tab "ลงประกาศขาย" แทน** (เช่น `IconButton(icon: Icon(Icons.history), onPressed: () => Navigator.push(...))`) เพิ่ม `AppBar` ให้ `SellItemPage` ถ้ายังไม่มี แล้วใส่ปุ่มนี้ไว้ที่ `actions`

> ✅ **Checkpoint 5.1** รันแอปแล้วทำตามลำดับนี้: 1. สร้างร่างประกาศใหม่ผ่าน Tab "ลงประกาศขาย" ด้วยความช่วยเหลือของ AI เหมือนสัปดาห์ที่ 7 2. กดยืนยันร่าง 3. กดปุ่มไอคอนเข้าหน้า "ร่างประกาศของฉัน" แล้วเห็นร่างที่เพิ่งสร้าง 4. ปิดแอปให้สนิทแล้วเปิดใหม่ กลับเข้าหน้า "ร่างประกาศของฉัน" อีกครั้ง ถ่ายภาพหน้าจอทั้ง 4 ขั้นตอนนี้แนบส่ง เพื่อพิสูจน์ว่าร่างไม่หายไปแม้ปิดแอปแล้ว 

1
<img width="1080" height="2400" alt="Screenshot_20261006_210357" src="https://github.com/user-attachments/assets/880fb828-dfb4-4a61-b145-38163388e09f" />
2
<img width="1080" height="2400" alt="Screenshot_20261006_210404" src="https://github.com/user-attachments/assets/85918572-2128-4dce-9043-244dd31ff273" />
3
<img width="1080" height="2400" alt="Screenshot_20261006_210414" src="https://github.com/user-attachments/assets/6a57d3fc-82d1-48dc-bc12-79bad55a0f88" />
4
<img width="1080" height="2400" alt="Screenshot_20261006_210534" src="https://github.com/user-attachments/assets/7dee1da3-5ece-4a8e-acd5-4a784117b2b5" />

---

## ส่วนที่ 6: ทดสอบสถานการณ์ Offline-first

### ขั้นตอนที่ 6.1: ปิดอินเทอร์เน็ตแล้วทดสอบ 🔧 ทำตามขั้นตอน

ปิด Wi-Fi และ Data บนอุปกรณ์ทดสอบ แล้วเปิดแอป `campus_marketplace_w7` เข้าไปที่ Tab "รายการโปรด" และหน้า "ร่างประกาศของฉัน"

> ✅ **Checkpoint 6.1** ถ่ายภาพหน้าจอที่แสดงให้เห็นว่า Tab รายการโปรดและหน้าร่างประกาศยังคงแสดงข้อมูลได้ตามปกติแม้ไม่มีอินเทอร์เน็ตเลย (ส่วน Tab หน้าหลักที่ดึงจาก Fake Store API คาดว่าจะแสดง Error ตามปกติ เพราะยังไม่ได้ทำ Local Cache ให้หน้านั้น) 

<img width="1080" height="2400" alt="Screenshot_20261006_210957" src="https://github.com/user-attachments/assets/2365288e-09c0-4b06-842f-e1d114ed7181" />
<img width="1080" height="2400" alt="Screenshot_20261006_210950" src="https://github.com/user-attachments/assets/44e19ec5-4cde-4598-a22f-5e58fb81ee04" />


---

## ปัญหาที่พบบ่อยและวิธีแก้ไข (Troubleshooting)

**Error พูดถึง Class `ListingDraft` ชนกัน หรือ `The name 'ListingDraft' is defined in multiple libraries`** เกิดจากลืมใส่ `@DataClassName('ListingDraftRow')` บนตาราง `ListingDrafts` ใน `tables.dart` ตามที่เตือนไว้ใน Checkpoint 2.1 ทำให้ Drift สร้าง Class ชื่อ `ListingDraft` ซ้ำกับ Class เดิมจากสัปดาห์ที่ 7 ให้เพิ่ม Annotation นี้แล้วรัน `dart run build_runner build --delete-conflicting-outputs` ใหม่อีกครั้ง

**Error: `Target of URI hasn't been generated: 'app_database.g.dart'`** เกิดจากยังไม่ได้รันคำสั่ง `dart run build_runner build --delete-conflicting-outputs` หรือรันแล้วแต่มีข้อผิดพลาดระหว่างสร้างโค้ดที่ยังไม่ได้แก้ไข ให้ตรวจสอบผลลัพธ์ในเทอร์มินัลตอนรันคำสั่งนี้ให้ละเอียด มักมีข้อความบอกบรรทัดที่ผิดพลาดในไฟล์ `tables.dart`

**รัน `build_runner` แล้วค้างนานผิดปกติหรือ error ว่า `Conflicting outputs`** ให้ลองรันคำสั่ง `dart run build_runner clean` ก่อน แล้วค่อยรัน `dart run build_runner build --delete-conflicting-outputs` ใหม่อีกครั้ง

**`The named parameter 'favoritesRepository'/'draftRepository' isn't defined` ตอนแก้ `main_scaffold.dart`/`home_page.dart`/`sell_item_page.dart`** เกิดจากแก้ Constructor ของไฟล์หนึ่งแล้ว แต่ยังไม่ได้แก้จุดที่เรียกใช้ Widget นั้นให้ส่งพารามิเตอร์ใหม่ครบ ให้ไล่ตรวจทั้ง 3 ไฟล์ตามลำดับ: `main.dart` → `main_scaffold.dart` → `home_page.dart`/`sell_item_page.dart` ว่าชื่อพารามิเตอร์ตรงกันทุกจุด

**แอป Error ทันทีตอนเปิด บอกประมาณ `RangeError` หรือ Bottom Navigation Bar กับหน้าจอไม่ตรงกัน** เกิดจากจำนวนรายการใน List `pages` ของ `MainScaffold` ไม่เท่ากับจำนวน `BottomNavigationBarItem` (ต้องเป็น 3 รายการทั้งคู่หลังทำ Checkpoint 4.1) ให้ตรวจนับทั้งสองรายการให้ตรงกัน

**แอป Crash ด้วยข้อความเกี่ยวกับ `sqlite3` ตอนรันบน Android จริง** ตรวจสอบว่าเพิ่ม `sqlite3_flutter_libs` ใน `pubspec.yaml` ครบถ้วนแล้ว และรัน `flutter clean` ตามด้วย `flutter pub get` ใหม่อีกครั้งก่อนรันแอป

**ข้อมูลหายไปหลังแก้ไขโครงสร้างตาราง (เพิ่ม/ลบคอลัมน์)** เกิดจากไม่ได้เพิ่มค่า `schemaVersion` และเขียนโค้ด Migration รองรับ ตามที่เตือนไว้ในบทหนังสือเรียนหัวข้อ 8.4 ระหว่างพัฒนา (ยังไม่ปล่อยให้ผู้ใช้จริงใช้งาน) วิธีแก้ชั่วคราวที่ง่ายที่สุดคือถอนการติดตั้งแอปออกจากอุปกรณ์ทดสอบแล้วติดตั้งใหม่ เพื่อล้างไฟล์ฐานข้อมูลเก่าทิ้ง (ห้ามใช้วิธีนี้กับแอปที่ผู้ใช้จริงติดตั้งอยู่แล้ว)

**หน้า Favorites/My Drafts แสดงค้างที่ Loading ตลอด ไม่ขึ้นข้อมูล** มักเกิดจากลืมเรียก `setState()` หลังจากได้ผลลัพธ์จาก `await repository.getAllFavorites()`/`getAllDrafts()` กลับมา (โดยเฉพาะหลังกดลบแล้วต้องการให้ List รีเฟรช) ตรวจสอบตามรูปแบบเดียวกับที่แก้ปัญหานี้มาแล้วในสัปดาห์ที่ 6

**กดหัวใจที่หน้า Home แล้วไม่มีอะไรเกิดขึ้นเลย ไม่มี Error ด้วย** มักเกิดจากลืม `await` หน้า `addFavorite(...)` หรือลืมเขียนโค้ดแสดง `SnackBar` หลังเรียกสำเร็จ ให้ตรวจสอบว่าฟังก์ชันใน `onPressed` ประกาศเป็น `async` และมี `await` ก่อนเรียก `ScaffoldMessenger.of(context).showSnackBar(...)`

**กดหัวใจซ้ำที่สินค้าชิ้นเดิมแล้วแอป Error ด้วยข้อความเกี่ยวกับ `UNIQUE constraint failed`** เกิดจากลืมใส่ `mode: InsertMode.insertOrIgnore` ตอนเรียก `_db.into(_db.favoriteItems).insert(...)` ใน `addFavorite()` เพราะคอลัมน์ `itemId` ถูกกำหนดเป็น `.unique()` ไว้ใน `tables.dart` (Checkpoint 2.1) ทำให้ Insert ซ้ำ `itemId` เดิมไม่ได้ ให้เพิ่มพารามิเตอร์ `mode: InsertMode.insertOrIgnore` เข้าไปในคำสั่ง `.insert(...)`
