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
  static const _prompt =
      '''คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว''';

  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;
  ListingDraft? _confirmedDraft;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _imageFile = File(image.path);
      _errorMessage = null;
      _confirmedDraft = null;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _analyzeImage() async {
    final image = _imageFile;
    if (image == null) {
      setState(() => _errorMessage = 'กรุณาเลือกรูปภาพสินค้าก่อน');
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _confirmedDraft = null;
    });
    try {
      final draft = await GeminiVisionService().analyzeProductImage(
        imageFile: image,
        prompt: _prompt,
      );
      if (!mounted) return;
      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
      });
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _confirmDraft() async {
    if (_titleController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      setState(
        () => _errorMessage = 'กรุณากรอกข้อมูลร่างประกาศให้ครบทั้ง 3 ช่อง',
      );
      return;
    }
    final draft = ListingDraft(
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final imagePath = _imageFile?.path ?? '';
      await widget.draftRepository.saveDraft(draft, imagePath);
      if (!mounted) return;
      setState(() => _confirmedDraft = draft);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว')),
      );
      setState(() {
        _imageFile = null;
        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'บันทึกร่างประกาศไม่สำเร็จ: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
            tooltip: 'ร่างประกาศของฉัน',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 220,
            child: _imageFile == null
                ? const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xffeeeeee)),
                    child: Center(child: Icon(Icons.image_outlined, size: 72)),
                  )
                : Image.file(_imageFile!, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (_isAnalyzing || _isSaving) ? null : _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('เลือกรูปภาพสินค้า'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: (_isAnalyzing || _isSaving) ? null : _analyzeImage,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('ให้ AI ช่วยแนะนำ'),
          ),
          if (_isAnalyzing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Center(child: Text('AI กำลังวิเคราะห์ภาพสินค้า...')),
          ],
          if (_isSaving) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Center(child: Text('กำลังบันทึกร่างประกาศลงฐานข้อมูล...')),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'ตรวจทานและแก้ไขก่อนยืนยัน',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'ชื่อประกาศ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'หมวดหมู่',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'คำบรรยายสินค้า',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_isAnalyzing || _isSaving) ? null : _confirmDraft,
            child: const Text('ยืนยันร่างประกาศ'),
          ),
          if (_confirmedDraft != null) ...[
            const SizedBox(height: 16),
            Text('ร่างล่าสุด: ${_confirmedDraft!.title}'),
          ],
        ],
      ),
    );
  }
}
