import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/gemini_vision_service.dart';
import 'my_drafts_page.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  const SellItemPage({super.key, required this.draftRepository});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  // ── State: รูปภาพ ──────────────────────────────────────────────────────────
  File? _selectedImage;

  // ── State: 3 สถานะของ AI (กำลังวิเคราะห์ / สำเร็จ / ผิดพลาด) ─────────────
  bool _isAnalyzing = false;
  String? _errorMessage;
  ListingDraft? _draft;

  // ── TextEditingController สำหรับฟอร์มตรวจทานและแก้ไข (ขั้นตอนที่ 5.1) ──────
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── เลือกรูปภาพจากคลังภาพ ─────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      // รีเซ็ตผลลัพธ์เดิมเมื่อเลือกรูปใหม่
      _draft = null;
      _errorMessage = null;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  // ── เรียก Gemini Vision วิเคราะห์รูปภาพ ────────────────────────────────────
  Future<void> _analyzeWithAI() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _draft = null;
    });

    try {
      final result = await GeminiVisionService().analyzeProductImage(
        _selectedImage!,
      );
      if (mounted) {
        setState(() {
          _draft = result;
          // นำค่าที่ AI แนะนำไปใส่ใน TextEditingController 3 ช่อง เพื่อให้ผู้ใช้แก้ไขได้
          _titleController.text = result.title;
          _categoryController.text = result.category;
          _descriptionController.text = result.description;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _errorMessage = errorMsg;
          _draft = null;
          _isAnalyzing = false;
        });
        debugPrint('AI Error: $_errorMessage');
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ── ยืนยันร่างประกาศ (ขั้นตอนที่ 5.2 บันทึกถาวรด้วย Drift) ────────────────────────
  bool _isSaving = false;

  Future<void> _confirmDraft() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อประกาศก่อนยืนยัน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final finalDraft = ListingDraft(
      title: title,
      category: category,
      description: description,
    );

    setState(() => _isSaving = true);

    try {
      final imagePath = _selectedImage?.path ?? '';
      await widget.draftRepository.saveDraft(finalDraft, imagePath);

      if (mounted) {
        setState(() {
          _selectedImage = null;
          _draft = null;
          _errorMessage = null;
          _titleController.clear();
          _categoryController.clear();
          _descriptionController.clear();
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ร่างประกาศของฉัน',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyDraftsPage(
                    draftRepository: widget.draftRepository,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── พื้นที่แสดงรูปภาพ ──────────────────────────────────────────
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('ยังไม่ได้เลือกรูปภาพ',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // ── ปุ่มเลือกรูปภาพ ───────────────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
              onPressed: _isAnalyzing ? null : _pickImage,
            ),

            const SizedBox(height: 12),

            // ── ปุ่มให้ AI ช่วยแนะนำ ──────────────────────────────────────
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
              onPressed: (_selectedImage == null || _isAnalyzing) ? null : _analyzeWithAI,
            ),

            const SizedBox(height: 24),

            // ── สถานะที่ 1: กำลังวิเคราะห์ ────────────────────────────────
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'AI กำลังวิเคราะห์ภาพสินค้า...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),


            // ── สถานะที่ 3: วิเคราะห์สำเร็จ — แสดงฟอร์มตรวจทานและแก้ไข (ขั้นตอนที่ 5.1 & 5.2) ──
            if (_draft != null) _buildReviewAndEditForm(),
          ],
        ),
      ),
    );
  }

  /// Widget ฟอร์มตรวจทานและแก้ไขข้อมูลก่อนยืนยัน (Human-in-the-loop)
  Widget _buildReviewAndEditForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.indigo, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ตรวจทานและแก้ไขร่างประกาศ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'AI แนะนำ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'สามารถแก้ไขข้อความที่ AI แนะนำได้ก่อนกดยืนยัน',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Divider(height: 24),

            // ช่องที่ 1: ชื่อประกาศ
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อประกาศ',
                hintText: 'กรอกชื่อประกาศ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),

            // ช่องที่ 2: หมวดหมู่
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                hintText: 'เช่น หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),

            // ช่องที่ 3: คำบรรยาย
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'คำบรรยาย',
                hintText: 'กรอกคำบรรยายสินค้า',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // ปุ่มยืนยันร่างประกาศ
            FilledButton.icon(
              onPressed: _isSaving ? null : _confirmDraft,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? 'กำลังบันทึก...' : 'ยืนยันร่างประกาศ'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
