# รายงานผลปฏิบัติการสัปดาห์ที่ 8
---

## ส่วนที่ 1: ใช้ AI ช่วยร่าง Schema

### ขั้นตอนที่ 1.1: ผลลัพธ์จาก Gemini

คัดลอกคำตอบจาก Gemini หรือสรุป Schema ที่ Gemini เสนอ:

```text
นี่คือโค้ด Dart สำหรับนิยามตารางทั้งสองตารางด้วย Drift
พร้อมคำอธิบายชนิดข้อมูลและเหตุผลประกอบครับ

โค้ด Dart (Drift Table Definitions)

import 'package:drift/drift.dart';

// ----------------------------------------------------------------------
// ตารางที่ 1: รายการสินค้าที่ถูกใจ (Liked Products / Favorites Cache)
// ----------------------------------------------------------------------
class LikedProducts extends Table {
  // รหัสสินค้าจากระบบหลัก (Primary Key ป้องกันการกดซ้ำ และใช้ค้นหาได้ทันที)
  IntColumn get productId => integer()();

  // ชื่อสินค้า
  TextColumn get title => text()();

  // ราคาสินค้า
  RealColumn get price => real()();

  // URL หรือ Path รูปภาพพรีวิวสำหรับแสดงผลออฟไลน์
  TextColumn get imageUrl => text()();

  // วันและเวลาที่กดถูกใจ (ค่าเริ่มต้นเป็นเวลาปัจจุบัน)
  DateTimeColumn get likedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {productId};
}

// ----------------------------------------------------------------------
// ตารางที่ 2: ร่างประกาศขายสินค้าจาก AI (AI Product Drafts)
// ----------------------------------------------------------------------
class ProductDrafts extends Table {
  // รหัสของร่างประกาศ รันเลขอัตโนมัติ
  IntColumn get id => integer().autoIncrement()();

  // Path ของรูปภาพต้นฉบับในเครื่องที่ใช้ให้ AI วิเคราะห์
  TextColumn get localImagePath => text()();

  // ชื่อประกาศ (nullable เผื่อกรณี AI กำลังประมวลผลหรือยังตั้งชื่อไม่เสร็จ)
  TextColumn get title => text().nullable()();

  // หมวดหมู่สินค้าที่ AI แนะนำ
  TextColumn get category => text().nullable()();

  // คำบรรยายสินค้าที่ AI เจนให้
  TextColumn get description => text().nullable()();

  // วันและเวลาที่แก้ไขล่าสุด
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

รายละเอียดและเหตุผลในการเลือกชนิดข้อมูล (Column Type)

ตารางที่ 1: LikedProducts

| คอลัมน์         | ชนิดข้อมูลใน Drift | ชนิดข้อมูล SQLite     | เหตุผลที่เลือก                                                                                                                                                                                            |
| :-------------- | :----------------- | :-------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`productId`** | `IntColumn`        | `INTEGER`             | อ้างอิง ID สินค้าที่เป็นตัวเลขตามโจทย์ และกำหนดให้เป็น **Primary Key** ของตารางนี้ทันที เพื่อบังคับว่าสินค้า 1 ชิ้นจะถูกบันทึกได้เพียงรายการเดียว (Uniqueness) ช่วยตัดปัญหาข้อมูลซ้ำซ้อน                  |
| **`title`**     | `TextColumn`       | `TEXT`                | เก็บชื่อสินค้าแบบข้อความ (String) ความยาวไม่จำกัด                                                                                                                                                         |
| **`price`**     | `RealColumn`       | `REAL`                | เก็บค่าตัวเลขทศนิยม (`double`) เหมาะกับราคาสินค้าทั่วไป เช่น `150.00` หรือ `99.50` *(หากแอปต้องการความแม่นยำระดับสตางค์แบบเคร่งครัด สามารถเลี่ยงไปใช้ `IntColumn` แล้วคูณ 100 เก็บเป็นสตางค์ได้)*         |
| **`imageUrl`**  | `TextColumn`       | `TEXT`                | เก็บสตริงของ URL หรือ Cache Key รูปภาพ เพื่อนำไปโหลดแสดงผลได้ทันทีโดยไม่ต้องยิง API รายละเอียดสินค้า                                                                                                      |
| **`likedAt`**   | `DateTimeColumn`   | `INTEGER` (Timestamp) | ใช้จัดเก็บวันเวลาที่กดถูกใจ โดยตั้งค่า `.withDefault(currentDateAndTime)` เพื่อให้ SQLite บันทึกเวลาอัตโนมัติ ช่วยให้ Query เรียงลำดับได้ง่ายด้วยคำสั่ง `.orderBy([(t) => OrderingTerm.desc(t.likedAt)])` |

ตารางที่ 2: ProductDrafts

| คอลัมน์              | ชนิดข้อมูลใน Drift | ชนิดข้อมูล SQLite     | เหตุผลที่เลือก                                                                                                                                                             |
| :------------------- | :----------------- | :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`id`**             | `IntColumn`        | `INTEGER`             | ใช้ `.autoIncrement()` ให้ระบบสร้าง ID อัตโนมัติและเป็น Primary Key ทำให้ผู้ใช้สามารถมีร่างประกาศหลายชิ้นพร้อมกันได้                                                       |
| **`localImagePath`** | `TextColumn`       | `TEXT`                | เก็บสตริง File Path รูปภาพในอุปกรณ์ (เช่น `/data/user/0/.../cache/image.jpg`) คอลัมน์นี้ไม่เป็น Null เพราะเป็นจุดเริ่มต้นที่ผู้ใช้ถ่ายภาพหรือเลือกภาพส่งให้ AI             |
| **`title`**          | `TextColumn`       | `TEXT` (Nullable)     | ใช้ `.nullable()` เนื่องจากสถานะ "ฉบับร่าง (Draft)" อาจมีบางช่วงที่ AI ยังวิเคราะห์ไม่เสร็จ หรือผู้ใช้ลบข้อมูลออกเพื่อรอแก้ไขภายหลัง                                       |
| **`category`**       | `TextColumn`       | `TEXT` (Nullable)     | เก็บหมวดหมู่สินค้าที่ AI คาดเดา (เช่น เสื้อผ้า, หนังสือเรียน) มีสิทธิ์เป็น Null หาก AI ไม่แน่ใจ                                                                            |
| **`description`**    | `TextColumn`       | `TEXT` (Nullable)     | เก็บเนื้อหารายละเอียดสินค้าจาก AI เป็น Nullable รองรับการแก้ไขเพิ่มเติม                                                                                                    |
| **`updatedAt`**      | `DateTimeColumn`   | `INTEGER` (Timestamp) | ใช้บันทึกเวลาแก้ไขล่าสุด เพื่อให้หน้าแสดงรายการ Draft สามารถเรียงประกาศที่เพิ่งแก้ไขขึ้นมาไว้บนสุดได้ (ตอน Update ข้อมูลในโค้ดให้อัปเดตฟิลด์นี้เป็น `DateTime.now()` เสมอ) |

ข้อแนะนำเพิ่มเติมสำหรับการนำไปใช้งาน

1.  การเรียงลำดับตารางถูกใจ: หากตาราง LikedProducts มีข้อมูลเพิ่มขึ้นจำนวนมาก
    การสร้าง Index ให้คอลัมน์ likedAt
    จะช่วยให้ดึงรายการที่ถูกใจล่าสุดได้รวดเร็วยิ่งขึ้น:
    @override
    List<Set<Column>> get uniqueKeys => [];
    // หรือสร้าง Table Index ใน Database class
2.  การอัปเดต Draft: เมื่อผู้ใช้พิมพ์แก้ไขข้อความในแบบฟอร์มร่างประกาศ อย่าลืมส่ง
    Value(DateTime.now()) เข้าไปที่ฟิลด์ updatedAt
    เพื่อให้เวลาอัปเดตเป็นปัจจุบันเสมอ

```

**แนบภาพหน้าจอผลลัพธ์จาก Gemini:**  

![alt text](/img/image.png)

![alt text](/img/image-1.png)

### ขั้นตอนที่ 1.2: ตรวจสอบและเทียบกับหลักการในบทเรียน

1. **Gemini กำหนด Primary Key ของแต่ละตารางถูกต้องหรือไม่** (ควรเป็น Auto-increment Integer) อธิบาย:

   คำตอบ: ตารางที่ 1 (LikedProducts / Favorites) Gemini กำหนดให้ productId เป็น Primary Key โดยตรงผ่าน @override Set<Column> get primaryKey => {productId}; ซึ่งยังไม่ตรงกับแนวทางในบทเรียน แต่ให้สร้างคอลัมน์ id แยกต่างหากแบบ Auto-increment Integer (IntColumn get id => integer().autoIncrement()();) เพื่อเป็น Surrounding/Surrogate Primary Key ประจำตาราง Local DB

2. **Gemini เลือกชนิดข้อมูลของราคาสินค้าเป็นอะไร** ตรงกับ `RealColumn`/`double` ที่บทเรียนแนะนำหรือไม่ ถ้าไม่ตรง จะแก้เป็นอะไร:

   คำตอบ: Gemini เลือกใช้ RealColumnซึ่งตรงตามที่บทเรียนแนะนำอย่างถูกต้อง

3. **Gemini เสนอให้เก็บสำเนาข้อมูลสินค้าใน Favorites หรือไม่** อธิบายว่าทำไมการเก็บเพียง `itemId` แล้วเรียก API ใหม่จึงไม่เหมาะเมื่อไม่มีอินเทอร์เน็ต:

   คำตอบ: Gemini เลือกเก็บสำเนาข้อมูล (title, price, imageUrl) ซ้ำไว้ในตาราง Favorites ด้วย ไม่ได้เก็บเพียง itemId หากเลือกเก็บเฉพาะ itemId เพื่อลดความซ้ำซ้อนของข้อมูล ทุกครั้งที่ผู้ใช้เปิดหน้าต่างรายการโปรด แอปพลิเคชันจะต้องส่ง Network Request ไปดึงรายละเอียดสินค้าจาก REST API ใหม่ทั้งหมด หากผู้ใช้เปิดแอปในจุดที่ไม่มีสัญญาณอินเทอร์เน็ต หน้าจอจะไม่สามารถแสดงชื่อ ราคา หรือรูปภาพสินค้าได้เลย การเก็บสำเนาข้อมูลที่จำเป็น จึงตอบโจทย์ Offline-first

4. **Gemini กำหนดให้ `itemId` ไม่ซ้ำด้วย `.unique()` หรือไม่** หากไม่ได้กำหนด ควรปรับอย่างไร และเพราะเหตุใด:

   คำตอบ: Gemini ไม่ได้ใช้ .unique() บนคอลัมน์รหัสสินค้าโดยตรง วิธีปรับแก้คือเพิ่มคอลัมน์ id แบบ Auto-increment และปรับคอลัมน์รหัสสินค้าให้ระบุข้อบังคับ .unique() ให้ชัดเจน

**Checkpoint 1.1 – หลักฐาน:** ใช้ภาพหน้าจอ Gemini ที่แนบไว้ในขั้นตอน 1.1

---

## ส่วนที่ 2: ติดตั้ง Drift และประกาศตาราง

บันทึกผลการเพิ่ม dependencies และการรัน `flutter pub get`:

**ผลลัพธ์/ข้อความสำคัญจากคำสั่ง:**

```text
Resolving dependencies... 
Downloading packages... 
  _fe_analyzer_shared 100.0.0 (109.0.0 available)
  analyzer 13.0.0 (14.5.0 available)
  build 4.0.7 (5.0.0 available)
  build_config 1.3.3 (1.4.0 available)
  build_runner 2.15.1 (2.17.1 available)
  clock 1.1.2 (1.1.3 available)
  code_assets 1.2.1 (2.1.0 available)
  cross_file 0.3.5+5 (0.4.0 available)
  cupertino_icons 1.0.9 (2.0.0 available)
  dart_style 3.1.9 (3.1.14 available)
  hooks 2.0.2 (2.2.0 available)
  image_picker 1.2.3 (1.2.4 available)
  image_picker_android 0.8.13+23 (0.8.13+25 available)
  image_picker_ios 0.8.13+9 (0.8.13+12 available)
  image_picker_platform_interface 2.11.1 (2.11.2 available)
  matcher 0.12.19 (0.12.20 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  meta 1.18.0 (1.19.0 available)
  native_toolchain_c 0.19.2 (0.19.5 available)
  objective_c 9.5.0 (9.6.2 available)
  package_config 2.2.0 (3.0.0 available)
  record_use 0.6.0 (1.1.1 available)
  source_gen 4.2.4 (4.3.1 available)
  sqlite3 3.5.2 (3.7.1 available)
  sqlite3_flutter_libs 0.5.42 (0.6.0+eol available)
  stack_trace 1.12.1 (1.12.2 available)
  test_api 0.7.11 (0.7.15 available)
  vector_math 2.2.0 (2.4.3 available)
  vm_service 15.3.0 (15.4.0 available)
Got dependencies!
29 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```

---

## ส่วนที่ 3: สร้าง AppDatabase และรัน Code Generation

### ขั้นตอนที่ 3.1–3.2: ผลการรัน Code Generation

บันทึกผลจากคำสั่ง:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**ผลลัพธ์จากเทอร์มินัล:**

```text
>dart run build_runner build --delete-conflicting-outputs
Building package executable... (5.8s)
29s compiling builders/aot                                                                      
8s drift_dev on 60 inputs: 15 skipped, 29 output, 16 no-op; spent 3s analyzing, 3s sdk          
0s source_gen:combining_builder on 30 inputs: 15 skipped, 1 output, 14 no-op                             
build_runner                                                                                    
W These options have been removed and were ignored: --delete-conflicting-outputs                
                                                                                          
Built with build_runner/aot in 41s with warnings; wrote 30 outputs.  
```

**Checkpoint 3.1 – แนบภาพหน้าจอผลลัพธ์ build_runner ที่แสดงว่าสร้างไฟล์สำเร็จ:**  

![alt text](/img/image-2.png)

### ขั้นตอนที่ 3.3: เชื่อม AppDatabase เข้ากับแอป

![alt text](/img/image-3.png)

---

## ส่วนที่ 4: สร้างฟีเจอร์รายการโปรด (Favorites)

### Checkpoint 4.1: ทดสอบ Favorites และการบันทึกถาวร

**แนบภาพ: รายการโปรดแสดงครบ 3 รายการ (ก่อนปิดแอป):**  

![alt text](/img/image-4.png)

**แนบภาพ: รายการเดิมหลังปิดและเปิดแอปใหม่:**  

![alt text](/img/image-5.png)

**แนบภาพ: ผลหลังลบรายการและทดสอบกดหัวใจซ้ำ (ถ่ายแยกได้):**  

![alt text](/img/image-6.png)

![alt text](/img/image-7.png)

---

## ส่วนที่ 5: บันทึกร่างประกาศขายสินค้าอย่างถาวร

### ขั้นตอนที่ 5.1–5.3: ผลการทำงาน

### Checkpoint 5.1: ทดสอบร่างประกาศ

**ภาพที่ 1 – ร่างแสดงในหน้า My Drafts:**  

![alt text](/img/image-8.png)

**ภาพที่ 2 – ร่างยังอยู่หลังปิดและเปิดแอปใหม่:**  

![alt text](/img/image-9.png)

---

## ส่วนที่ 6: ทดสอบสถานการณ์ Offline-first

### Checkpoint 6.1: ปิดอินเทอร์เน็ตแล้วทดสอบ

**แนบภาพหน้าจอ Tab รายการโปรดขณะ Offline:**  

![alt text](/img/image-10.png)

![alt text](/img/image-12.png)

**แนบภาพหน้าจอหน้า My Drafts ขณะ Offline:**  

![alt text](/img/image-11.png)

---