import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/book_models.dart';
import 'status_badge.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.compact = false,
    this.showRecommended = false,
    this.recommendationReason,
  });

  final BookListDto book;
  final VoidCallback? onTap;
  final bool compact;
  final bool showRecommended;
  final String? recommendationReason;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveMediaUrl(book.coverImagePath);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: compact ? _buildCompact(context, imageUrl) : _buildFull(context, imageUrl),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, String imageUrl) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              _cover(imageUrl, height: 175),
              if (showRecommended)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.recommendedBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  book.authorsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
                if (recommendationReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    recommendationReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                StatusBadge(
                  status: book.isAvailable ? 'Available' : 'Borrowed',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, String imageUrl) {
    return Row(
      children: [
        _cover(imageUrl, width: 90, height: 120),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(book.authorsLabel),
                const SizedBox(height: 4),
                Text(
                  '${book.genreName} · ${book.publisherName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (recommendationReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    recommendationReason!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                StatusBadge(
                  status: book.isAvailable ? 'Available' : 'Borrowed',
                ),
              ],
            ),
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  Widget _cover(String imageUrl, {double? width, double? height}) {
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.menu_book, size: 40, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
