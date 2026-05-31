import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../widgets/data_table.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsItem> _items = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<AuthProvider>().authService.api;
      final items = await api.getNews(search: _searchController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showNewsDialog({NewsItem? item}) async {
    final titleController = TextEditingController(text: item?.title ?? '');
    final contentController = TextEditingController(text: item?.content ?? '');
    final imageController = TextEditingController(text: item?.imagePath ?? '');
    var isActive = item?.isActive ?? true;
    var publishedAt = item?.publishedAt.toLocal() ?? DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add News' : 'Edit News'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content *'),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image path',
                      hintText: '/uploads/seed/news-welcome.png',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published at'),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(publishedAt)),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: publishedAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date == null || !context.mounted) {
                          return;
                        }
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(publishedAt),
                        );
                        if (time == null) {
                          return;
                        }
                        setDialogState(() {
                          publishedAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) => setDialogState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) {
      return;
    }

    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
      );
      return;
    }

    final body = {
      'title': titleController.text.trim(),
      'content': contentController.text.trim(),
      'imagePath': imageController.text.trim().isEmpty ? null : imageController.text.trim(),
      'publishedAt': publishedAt.toUtc().toIso8601String(),
      'isActive': isActive,
    };

    try {
      final api = context.read<AuthProvider>().authService.api;
      if (item == null) {
        await api.createNews(body);
      } else {
        await api.updateNews(item.id, body);
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(item == null ? 'News item created.' : 'News item updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteNews(NewsItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete News'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await context.read<AuthProvider>().authService.api.deleteNews(item.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          const PageHeader(
            title: 'News',
            subtitle: 'Manage library announcements for mobile users',
          ),
        if (_error != null) ErrorBanner(message: _error!),
        Row(
          children: [
            SearchField(
              controller: _searchController,
              hint: 'Search news...',
              width: 360,
              onSearch: (_) => _load(),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showNewsDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add News'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AppDataTable(
            isLoading: _isLoading,
            emptyMessage: 'No news items found.',
            columns: const [
              DataColumn(label: Text('Image')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Published')),
              DataColumn(label: Text('Active')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _items.map((item) {
              final imageUrl = ApiConfig.resolveAssetUrl(item.imagePath);
              return DataRow(
                cells: [
                  DataCell(
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 48,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.article_outlined),
                    ),
                  ),
                  DataCell(Text(item.title)),
                  DataCell(Text(dateFormat.format(item.publishedAt.toLocal()))),
                  DataCell(Text(item.isActive ? 'Yes' : 'No')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showNewsDialog(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteNews(item),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
