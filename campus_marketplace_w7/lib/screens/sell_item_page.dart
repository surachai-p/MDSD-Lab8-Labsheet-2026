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
  File? _image;
  ListingDraft? _draft;

  bool _isAnalyzing = false;
  bool _isSaving = false;

  String? _errorMessage;

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
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _image = File(pickedFile.path);
        _draft = null;
        _errorMessage = null;

        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เลือกรูปไม่สำเร็จ: $e')));
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await GeminiVisionService().analyzeProductImage(_image!);

      if (!mounted) return;

      setState(() {
        _draft = result;

        _titleController.text = result.title;
        _categoryController.text = result.category;
        _descriptionController.text = result.description;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _confirmDraft() async {
    if (_draft == null || _image == null || _isSaving) return;

    final finalDraft = ListingDraft(
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (finalDraft.title.isEmpty ||
        finalDraft.category.isEmpty ||
        finalDraft.description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง')),
      );
      return;
    }

    if (finalDraft.title.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ชื่อประกาศต้องไม่เกิน 100 ตัวอักษร')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.draftRepository.saveDraft(finalDraft, _image!.path);

      if (!mounted) return;

      setState(() {
        _image = null;
        _draft = null;
        _errorMessage = null;

        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกร่างประกาศไม่สำเร็จ: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MyDraftsPage(draftRepository: widget.draftRepository),
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
            Container(
              height: 260,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.contain)
                  : const Icon(Icons.image, size: 80, color: Colors.grey),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isAnalyzing || _isSaving ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _image == null || _isAnalyzing || _isSaving
                  ? null
                  : _analyzeImage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
            ),

            if (_isAnalyzing) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('AI กำลังวิเคราะห์ภาพสินค้า...')),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                'วิเคราะห์ไม่สำเร็จ\n$_errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ],

            if (_draft != null) ...[
              const SizedBox(height: 24),

              const Text(
                'ตรวจทานและแก้ไขร่างประกาศ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'AI ช่วยแนะนำข้อมูลเบื้องต้น '
                'กรุณาตรวจสอบก่อนยืนยัน',
              ),

              const SizedBox(height: 16),

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
                  labelText: 'คำบรรยายสินค้า',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _confirmDraft,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isSaving ? 'กำลังบันทึกร่าง...' : 'ยืนยันร่างประกาศ',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
