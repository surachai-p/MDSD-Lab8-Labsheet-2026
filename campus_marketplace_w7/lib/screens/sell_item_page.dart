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
  static const String _prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';


  File? _image;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;
  ListingDraft? _draft;
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // ย่อรูปก่อนส่ง Gemini เพื่อลดขนาดข้อมูลที่อัปโหลดและเวลารอ
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _draft = null;
      _errorMessage = null;
    });
  }

  Future<void> _analyze() async {
    final image = _image;
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้าก่อน')),
      );
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _draft = null;
    });
    try {
      final json = await GeminiVisionService().analyzeProductImage(
        image,
        _prompt,
      );
      final draft = ListingDraft.fromJson(json);
      if (!mounted) return;
      _titleController.text = draft.title;
      _categoryController.text = draft.category;
      _descriptionController.text = draft.description;
      setState(() => _draft = draft);
    } catch (e) {
      debugPrint('Gemini Vision error: $e');
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    final draft = ListingDraft(
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    // คอลัมน์ title กำหนด withLength(min: 1, max: 100) ไว้ จึงตรวจก่อนส่งลงฐานข้อมูล
    if (draft.title.isEmpty || draft.title.length > 100) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ชื่อประกาศต้องมี 1-100 ตัวอักษร')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.draftRepository.saveDraft(draft, _image!.path);
      if (!mounted) return;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
      setState(() {
        _image = null;
        _draft = null;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('บันทึกร่างประกาศ "${draft.title}" แล้ว')),
      );
    } catch (e) {
      debugPrint('Save draft error: $e');
      // ใช้ SnackBar แทน _errorMessage เพื่อไม่ให้ฟอร์มที่ผู้ใช้แก้ไว้หายไป
      messenger.showSnackBar(
        SnackBar(content: Text('บันทึกร่างไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildResult() {
    if (_isAnalyzing) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('AI กำลังวิเคราะห์...'),
        ],
      );
    }
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      );
    }
    if (_draft == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI แนะนำให้แล้ว กรุณาตรวจทานและแก้ไขก่อนยืนยัน'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'ชื่อประกาศ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'หมวดหมู่',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'คำบรรยาย',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _confirm,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isSaving ? 'กำลังบันทึก...' : 'ยืนยันร่างประกาศ'),
          ),
        ),
      ],
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MyDraftsPage(repository: widget.draftRepository),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.contain)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 64),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyze,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
            ),
            const SizedBox(height: 16),
            _buildResult(),
          ],
        ),
      ),
    );
  }
}
