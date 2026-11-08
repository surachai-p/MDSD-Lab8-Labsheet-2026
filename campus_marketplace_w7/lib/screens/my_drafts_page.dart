import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const MyDraftsPage({
    super.key,
    required this.draftRepository,
  });

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    _draftsFuture = widget.draftRepository.getAllDrafts();
  }

  void _refreshDrafts() {
    setState(_loadDrafts);
  }

  String _formatDate(DateTime dateTime) {
    final date = dateTime.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  Future<void> _deleteDraft(ListingDraftRow draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบร่างประกาศ'),
        content: Text('ต้องการลบร่าง "${draft.title}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingIds.add(draft.id);
    });

    try {
      await widget.draftRepository.deleteDraft(draft.id);

      if (!mounted) return;

      setState(() {
        _deletingIds.remove(draft.id);
        _loadDrafts();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบร่างประกาศเรียบร้อยแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deletingIds.remove(draft.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบร่างประกาศไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
      ),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('โหลดข้อมูลร่างประกาศไม่สำเร็จ'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshDrafts,
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          final drafts = snapshot.data ?? [];

          if (drafts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refreshDrafts(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text('ยังไม่มีร่างประกาศ'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshDrafts(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: drafts.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final draft = drafts[index];
                final isDeleting = _deletingIds.contains(draft.id);

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.description_outlined),
                    ),
                    title: Text(
                      draft.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'หมวดหมู่: ${draft.category}\n'
                      'แก้ไขล่าสุด: ${_formatDate(draft.updatedAt)}',
                    ),
                    isThreeLine: true,
                    trailing: isDeleting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            tooltip: 'ลบร่าง',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteDraft(draft),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}