import 'dart:io';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _draftsFuture = widget.repository.getAllDrafts();
  }

  Future<void> _deleteDraft(ListingDraftRow draft) async {
    try {
      await widget.repository.deleteDraft(draft.id);
      if (!mounted) return;
      setState(() {
        _draftsFuture = widget.repository.getAllDrafts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบร่าง "${draft.title}" แล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบร่างไม่สำเร็จ: $error')),
      );
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('โหลดร่างประกาศไม่สำเร็จ: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _draftsFuture = widget.repository.getAllDrafts();
                      });
                    },
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(child: Text('ยังไม่มีร่างประกาศ'));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                leading: _DraftImage(imagePath: draft.imagePath),
                title: Text(draft.title),
                subtitle: Text(
                  '${draft.category}\nแก้ไขล่าสุด ${_formatDateTime(draft.updatedAt)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'ลบร่างประกาศ',
                  onPressed: () => _deleteDraft(draft),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DraftImage extends StatelessWidget {
  final String imagePath;

  const _DraftImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      return const SizedBox(
        width: 56,
        height: 56,
        child: Icon(Icons.image_not_supported_outlined),
      );
    }
    return Image.file(
      imageFile,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image),
    );
  }
}
