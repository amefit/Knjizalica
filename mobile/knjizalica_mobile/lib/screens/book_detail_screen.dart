import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/book_models.dart';
import '../models/reservation_models.dart';
import '../providers/books_provider.dart';
import '../services/api_service.dart';
import '../utils/api_error_parser.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.embedded = false,
  });

  final int bookId;
  final bool embedded;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  int? _selectedCopyId;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isReserving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant BookDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final provider = context.read<BooksProvider>();
    await provider.loadBookDetail(widget.bookId);
    final book = provider.selectedBook;
    if (book != null && book.copies.isNotEmpty) {
      final copy = book.copies.firstWhere(
        (c) => c.isAvailable,
        orElse: () => book.copies.first,
      );
      setState(() {
        _selectedCopyId = copy.id;
      });
      await provider.loadAvailability(copy.id, _focusedMonth);
    }
  }

  Future<void> _changeMonth(int delta) async {
    final candidate = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month);
    if (DateTime(candidate.year, candidate.month).isBefore(earliest)) {
      return;
    }

    setState(() {
      _focusedMonth = candidate;
    });
    if (_selectedCopyId != null) {
      await context
          .read<BooksProvider>()
          .loadAvailability(_selectedCopyId!, _focusedMonth);
    }
  }

  bool _isPastDate(DateTime day) {
    final today = DateTime.now();
    final normalized = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return normalized.isBefore(todayOnly);
  }

  void _onDaySelected(DateTime day, BooksProvider provider) {
    if (_isPastDate(day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot select dates before today.')),
      );
      return;
    }

    if (provider.isDayOccupied(day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This day is occupied (red).')),
      );
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = day;
        _rangeEnd = null;
      } else if (day.isBefore(_rangeStart!)) {
        _rangeStart = day;
      } else {
        _rangeEnd = day;
      }
    });
  }

  Future<void> _reserve() async {
    if (_selectedCopyId == null || _rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a copy and a date range on the calendar.'),
        ),
      );
      return;
    }

    if (_isPastDate(_rangeStart!) || _isPastDate(_rangeEnd!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot reserve dates before today.')),
      );
      return;
    }

    setState(() => _isReserving = true);

    try {
      final api = context.read<ApiService>();
      final request = CreateReservationRequest(
        bookCopyId: _selectedCopyId!,
        fromDate: DateTime(
          _rangeStart!.year,
          _rangeStart!.month,
          _rangeStart!.day,
        ),
        toDate: DateTime(
          _rangeEnd!.year,
          _rangeEnd!.month,
          _rangeEnd!.day,
          23,
          59,
          59,
        ),
      );
      await api.createReservation(request);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation submitted successfully.')),
      );
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
      });
      await context
          .read<BooksProvider>()
          .loadAvailability(_selectedCopyId!, _focusedMonth);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReserving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BooksProvider>();
    final book = books.selectedBook;

    final content = books.isLoading
        ? const LoadingWidget(message: 'Loading book details...')
        : book == null
            ? Center(
                child: Text(books.errorMessage ?? 'Book not found.'),
              )
            : _buildContent(context, books, book);

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(book?.title ?? 'Book details')),
      body: content,
    );
  }

  Widget _buildContent(
    BuildContext context,
    BooksProvider provider,
    BookDetailDto book,
  ) {
    final imageUrl = ApiConfig.resolveMediaUrl(book.coverImagePath);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                cacheKey: imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            book.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(book.authorsLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                status: book.isAvailable ? 'Available' : 'Borrowed',
              ),
              Chip(label: Text(book.genreName)),
              Chip(label: Text(book.categoryName)),
            ],
          ),
          if (book.description != null && book.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(book.description!),
          ],
          const SizedBox(height: 16),
          Text(
            'Select copy',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedCopyId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: book.copies
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(
                      '${c.inventoryCode} (${c.isAvailable ? 'Available' : 'Borrowed'})',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              setState(() {
                _selectedCopyId = value;
                _rangeStart = null;
                _rangeEnd = null;
              });
              if (value != null) {
                await provider.loadAvailability(value, _focusedMonth);
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Availability',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _canGoToPreviousMonth()
                        ? () => _changeMonth(-1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(DateFormat.yMMMM().format(_focusedMonth)),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppTheme.calendarBusy, 'Occupied'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.calendarFree, 'Free'),
            ],
          ),
          const SizedBox(height: 12),
          _AvailabilityCalendar(
            month: _focusedMonth,
            isOccupied: provider.isDayOccupied,
            isPast: _isPastDate,
            rangeStart: _rangeStart,
            rangeEnd: _rangeEnd,
            onDayTap: (day) => _onDaySelected(day, provider),
          ),
          const SizedBox(height: 16),
          if (_rangeStart != null)
            Text(
              _rangeEnd == null
                  ? 'From: ${DateFormat.yMMMd().format(_rangeStart!)} — tap end date'
                  : 'Range: ${DateFormat.yMMMd().format(_rangeStart!)} – ${DateFormat.yMMMd().format(_rangeEnd!)}',
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isReserving ? null : _reserve,
              child: _isReserving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reserve selected dates'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canGoToPreviousMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year > now.year) {
      return true;
    }
    return _focusedMonth.year == now.year && _focusedMonth.month > now.month;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _AvailabilityCalendar extends StatelessWidget {
  const _AvailabilityCalendar({
    required this.month,
    required this.isOccupied,
    required this.isPast,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onDayTap,
  });

  final DateTime month;
  final bool Function(DateTime day) isOccupied;
  final bool Function(DateTime day) isPast;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Expanded(child: Center(child: Text(d))))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox.shrink();
            }
            final day = index - startWeekday + 1;
            final date = DateTime(month.year, month.month, day);
            final past = isPast(date);
            final occupied = isOccupied(date);
            final inRange = _isInRange(date);

            Color background;
            if (past) {
              background = Colors.grey.shade300;
            } else if (occupied) {
              background = AppTheme.calendarBusy;
            } else if (inRange) {
              background = AppTheme.primaryLight;
            } else {
              background = AppTheme.calendarFree;
            }

            return GestureDetector(
              onTap: past ? null : () => onDayTap(date),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: past
                        ? Colors.grey.shade600
                        : occupied || inRange
                            ? Colors.white
                            : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isInRange(DateTime day) {
    if (rangeStart == null) {
      return false;
    }
    final end = rangeEnd ?? rangeStart!;
    final start = rangeStart!.isBefore(end) ? rangeStart! : end;
    final finish = rangeStart!.isBefore(end) ? end : rangeStart!;
    return !day.isBefore(
          DateTime(start.year, start.month, start.day),
        ) &&
        !day.isAfter(DateTime(finish.year, finish.month, finish.day));
  }
}
