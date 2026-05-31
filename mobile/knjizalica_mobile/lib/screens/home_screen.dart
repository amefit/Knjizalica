import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/books_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/mobile_header.dart';
import 'book_detail_screen.dart';
import 'news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenSearch});

  final VoidCallback? onOpenSearch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _featuredController = ScrollController();

  @override
  void dispose() {
    _featuredController.dispose();
    super.dispose();
  }

  void _scrollFeatured(double delta) {
    _featuredController.animateTo(
      (_featuredController.offset + delta).clamp(
        0.0,
        _featuredController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BooksProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: books.isLoading && books.featured.isEmpty
            ? const LoadingWidget(message: 'Loading recommendations...')
            : RefreshIndicator(
                onRefresh: () => context.read<BooksProvider>().loadHome(),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    MobileHeader(
                      showSearch: true,
                      onSearchTap: widget.onOpenSearch,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const NewsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.article_outlined),
                        label: const Text('Library news & announcements'),
                      ),
                    ),
                    if (books.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          books.errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        children: [
                          const Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _scrollFeatured(-180),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: () => _scrollFeatured(180),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 292,
                      child: books.featured.isEmpty
                          ? const Center(child: Text('No featured books yet.'))
                          : ListView.separated(
                              controller: _featuredController,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: books.featured.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final book = books.featured[index];
                                return BookCard(
                                  book: book,
                                  compact: true,
                                  showRecommended: true,
                                  onTap: () => _openDetail(context, book.id),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    ...books.popular.map(
                      (book) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: BookCard(
                          book: book,
                          onTap: () => _openDetail(context, book.id),
                        ),
                      ),
                    ),
                    if (books.popular.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No popular books available.'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  void _openDetail(BuildContext context, int bookId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailScreen(bookId: bookId),
      ),
    );
  }
}
