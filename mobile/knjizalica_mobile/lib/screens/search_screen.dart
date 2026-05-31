import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book_models.dart';
import '../models/pagination_models.dart';
import '../providers/books_provider.dart';
import '../services/api_service.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  int? _selectedBookId;
  Timer? _debounce;
  List<LookupDto> _genres = [];
  List<LookupDto> _categories = [];
  int? _selectedGenreId;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksProvider>().search('');
      _loadFilters();
    });
  }

  Future<void> _loadFilters() async {
    try {
      final api = context.read<ApiService>();
      final genres = await api.getGenres();
      final categories = await api.getBookCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _genres = genres;
        _categories = categories;
      });
    } catch (_) {
      // Filters are optional; search still works without them.
    }
  }

  void _applyFilters() {
    context.read<BooksProvider>().applyFilters(
          genreId: _selectedGenreId,
          bookCategoryId: _selectedCategoryId,
        );
  }

  void _onSearchChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<BooksProvider>().search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _runSearchNow() {
    _debounce?.cancel();
    context.read<BooksProvider>().search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BooksProvider>();
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title or author',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _runSearchNow();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _runSearchNow(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedGenreId,
                    decoration: const InputDecoration(
                      labelText: 'Genre',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All genres'),
                      ),
                      ..._genres.map(
                        (g) => DropdownMenuItem<int?>(
                          value: g.id,
                          child: Text(g.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedGenreId = value);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (books.isSearching)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: isWide
                ? _MasterDetail(
                    books: books.searchResults,
                    selectedBookId: _selectedBookId,
                    onSelect: (id) => setState(() => _selectedBookId = id),
                  )
                : _BookList(
                    books: books.searchResults,
                    onTap: (id) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BookDetailScreen(bookId: id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books, required this.onTap});

  final List<BookListDto> books;
  final void Function(int bookId) onTap;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('No books found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(book: book, onTap: () => onTap(book.id));
      },
    );
  }
}

class _MasterDetail extends StatelessWidget {
  const _MasterDetail({
    required this.books,
    required this.selectedBookId,
    required this.onSelect,
  });

  final List<BookListDto> books;
  final int? selectedBookId;
  final void Function(int bookId) onSelect;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('No books found.'));
    }

    final selectedId = selectedBookId ?? books.first.id;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 8),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final book = books[index];
              final selected = book.id == selectedId;
              return Material(
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: BookCard(
                  book: book,
                  onTap: () => onSelect(book.id),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: BookDetailScreen(
            bookId: selectedId,
            embedded: true,
          ),
        ),
      ],
    );
  }
}
