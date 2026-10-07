import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const MyDraftsPage({super.key, required this.draftRepository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    setState(() {
      _draftsFuture = widget.draftRepository.getAllDrafts();
    });
  }

  Future<void> _deleteDraft(int id) async {
    await widget.draftRepository.deleteDraft(id);
    _loadDrafts(); // โหลดข้อมูลใหม่หลังลบ
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบร่างประกาศแล้ว')),
      );
    }
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
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีร่างประกาศ'));
          }

          final drafts = snapshot.data!;
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                title: Text(draft.title),
                subtitle: Text('หมวดหมู่: ${draft.category}'), // ตัดส่วน lastModified ออกแล้ว
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteDraft(draft.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}