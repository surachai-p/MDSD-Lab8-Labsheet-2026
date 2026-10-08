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
  File? _imageFile;
  bool _showForm = false; // ตัวแปรสำหรับซ่อน/แสดงช่องกรอกข้อมูล
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _analysisSucceeded = false;
  String? _errorMessage;

  static const String _prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายภาษาไทย 1 ประโยคสั้น ๆ ไม่เกิน 80 ตัวอักษร อิงเฉพาะสิ่งที่เห็นในภาพ"
}
ใช้ข้อความภาษาไทย ตอบเป็น JSON object ตามโครงสร้างเท่านั้น ห้ามมี Markdown หรือข้อความอื่น
''';

  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _analysisSucceeded = false;
      _errorMessage = null;
    });
  }

  Future<void> _analyzeProductImage() async {
    final imageFile = _imageFile;
    if (imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisSucceeded = false;
      _errorMessage = null;
    });

    try {
      final draft = await GeminiVisionService().analyzeProductImage(
        imageFile: imageFile,
        prompt: _prompt,
      );
      if (!mounted) return;

      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
        _showForm = true;
        _analysisSucceeded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _confirmDraft() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();
    final imageFile = _imageFile;

    if (title.isEmpty || category.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง')),
      );
      return;
    }
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้าอีกครั้ง')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final draft = ListingDraft(
      title: title,
      category: category,
      description: description,
    );
    try {
      await widget.draftRepository.saveDraft(draft, imageFile.path);
      if (!mounted) return;

      setState(() {
        _imageFile = null;
        _showForm = false;
        _analysisSucceeded = false;
        _errorMessage = null;
        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว: ${draft.title}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกร่างประกาศไม่สำเร็จ: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openMyDrafts() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MyDraftsPage(repository: widget.draftRepository),
      ),
    );
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
            onPressed: _openMyDrafts,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ส่วนแสดงรูปภาพสินค้า (ปรับทรงขอบมนเหมือนในรูป)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.file(_imageFile!, fit: BoxFit.contain),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('ยังไม่ได้เลือกรูปภาพสินค้า'),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // ปุ่มเลือกรูปภาพสินค้า
            ElevatedButton.icon(
              onPressed: _isAnalyzing || _isSaving ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 12),

            // ปุ่มให้ AI ช่วยแนะนำ
            ElevatedButton.icon(
              onPressed: _imageFile == null || _isAnalyzing || _isSaving
                  ? null
                  : _analyzeProductImage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
            ),

            if (_isAnalyzing) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('AI กำลังวิเคราะห์ภาพสินค้า...'),
                ],
              ),
            ],
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('กำลังบันทึกร่างประกาศ...'),
                ],
              ),
            ],
            if (_analysisSucceeded) ...[
              const SizedBox(height: 12),
              const Text(
                'AI วิเคราะห์สำเร็จ กรุณาตรวจสอบและแก้ไขข้อมูล',
                style: TextStyle(color: Colors.green),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                'วิเคราะห์ไม่สำเร็จ: $_errorMessage',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],

            // ช่องกรอกข้อมูล (จะแสดงเฉพาะเมื่อกดปุ่ม AI แล้วเท่านั้น)
            if (_showForm) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อประกาศ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'คำบรรยายสินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing || _isSaving ? null : _confirmDraft,
                  icon: const Icon(Icons.check),
                  label: Text(
                    _isSaving ? 'กำลังบันทึก...' : 'ยืนยันร่างประกาศ',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
