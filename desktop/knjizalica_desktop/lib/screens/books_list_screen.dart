import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/books_provider.dart';
import '../widgets/data_table.dart';
import '../widgets/status_badge.dart';
import 'book_form_screen.dart';

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({super.key, this.searchFocus = false});

  final bool searchFocus;

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  final _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BooksProvider>();
      _searchController.text = provider.search;
      provider.loadBooks();
      if (widget.searchFocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openForm({int? bookId}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookFormScreen(bookId: bookId),
      ),
    );
    if (result == true && mounted) {
      context.read<BooksProvider>().loadBooks();
    }
  }

  Future<void> _deleteBook(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "$title"?'),
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
      final ok = await context.read<BooksProvider>().deleteBook(id);
      if (!ok && mounted) {
        final error = context.read<BooksProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to delete book')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BooksProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Books',
          subtitle: 'Manage library catalog and inventory',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Book'),
            ),
          ],
        ),
        if (provider.error != null)
          ErrorBanner(
            message: provider.error!,
            onDismiss: () => provider.loadBooks(),
          ),
        Row(
          children: [
            SearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hint: 'Search books...',
              width: 400,
              onSearch: provider.applySearch,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AppDataTable(
            isLoading: provider.isLoading,
            emptyMessage: 'No books found.',
            columns: const [
              DataColumn(label: Text('Cover')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Authors')),
              DataColumn(label: Text('Genre')),
              DataColumn(label: Text('Publisher')),
              DataColumn(label: Text('Copies')),
              DataColumn(label: Text('Available today')),
              DataColumn(label: Text('Actions')),
            ],
            rows: provider.books.map((book) {
              final imageUrl = ApiConfig.resolveAssetUrl(book.coverImagePath);
              return DataRow(
                cells: [
                  DataCell(
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 40,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderCover(),
                            )
                          : _placeholderCover(),
                    ),
                  ),
                  DataCell(Text(book.title)),
                  DataCell(Text(book.authorNames.join(', '))),
                  DataCell(Text(book.genreName)),
                  DataCell(Text(book.publisherName)),
                  DataCell(Text('${book.availableCopies}/${book.totalCopies}')),
                  DataCell(StatusBadge(
                    status: book.isAvailable ? 'Available' : 'Unavailable',
                  )),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit',
                        onPressed: () => _openForm(bookId: book.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _deleteBook(book.id, book.title),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
        PaginationBar(
          page: provider.page,
          pageSize: provider.pageSize,
          totalCount: provider.totalCount,
          onPageChanged: (p) => provider.loadBooks(pageOverride: p),
        ),
      ],
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: 40,
      height: 56,
      color: Colors.grey.shade200,
      child: const Icon(Icons.menu_book, size: 20, color: Colors.grey),
    );
  }
}
