import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/books_provider.dart';
import '../widgets/data_table.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthorsProvider>().loadAuthors();
    });
  }

  Future<void> _showAuthorDialog({Author? author}) async {
    final firstNameController = TextEditingController(text: author?.firstName ?? '');
    final lastNameController = TextEditingController(text: author?.lastName ?? '');
    final bioController = TextEditingController(text: author?.biography ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(author == null ? 'Add Author' : 'Edit Author'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'First name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Last name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Biography'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    final provider = context.read<AuthorsProvider>();
    final ok = await provider.saveAuthor(
      id: author?.id,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      biography: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save author')),
      );
    }
  }

  Future<void> _deleteAuthor(Author author) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Author'),
        content: Text('Delete ${author.fullName}?'),
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

    if (confirmed == true && mounted) {
      final provider = context.read<AuthorsProvider>();
      final ok = await provider.deleteAuthor(author.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to delete author')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthorsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedded)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showAuthorDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Author'),
            ),
          )
        else
          PageHeader(
            title: 'Authors',
            subtitle: 'Manage book authors',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showAuthorDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Author'),
              ),
            ],
          ),
        if (provider.error != null) ErrorBanner(message: provider.error!),
        Expanded(
          child: AppDataTable(
            isLoading: provider.isLoading,
            emptyMessage: 'No authors found.',
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Biography')),
              DataColumn(label: Text('Actions')),
            ],
            rows: provider.authors.map((author) {
              return DataRow(cells: [
                DataCell(Text(author.fullName)),
                DataCell(Text(
                  author.biography ?? '—',
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showAuthorDialog(author: author),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _deleteAuthor(author),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
