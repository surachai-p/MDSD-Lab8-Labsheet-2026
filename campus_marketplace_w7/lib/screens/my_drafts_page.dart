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

  Future<void> _delete(ListingDraftRow draft) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.deleteDraft(draft.id);
      if (!mounted) return;
      setState(() {
        _draftsFuture = widget.repository.getAllDrafts();
      });
      messenger.showSnackBar(
        SnackBar(content: Text('ลบร่าง "${draft.title}" แล้ว')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    }
  }

  String _formatDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
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
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
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
                title: Text(draft.title),
                subtitle: Text(
                  '${draft.category}\n'
                  'แก้ไขล่าสุด ${_formatDateTime(draft.updatedAt)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'ลบร่าง',
                  onPressed: () => _delete(draft),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
