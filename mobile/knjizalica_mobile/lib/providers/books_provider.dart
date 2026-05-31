import 'package:flutter/foundation.dart';

import '../models/book_models.dart';
import '../models/recommendation_models.dart';
import '../models/reservation_models.dart';
import '../services/api_service.dart';
import '../utils/api_error_parser.dart';

class BooksProvider extends ChangeNotifier {
  BooksProvider(this._api);

  final ApiService _api;

  List<BookListDto> featured = [];
  List<BookListDto> popular = [];
  List<BookListDto> searchResults = [];
  BookDetailDto? selectedBook;
  AvailabilityCalendarDto? availability;
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;
  String _lastSearch = '';
  int? _genreId;
  int? _bookCategoryId;

  int? get genreId => _genreId;
  int? get bookCategoryId => _bookCategoryId;

  Future<void> loadHome() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final recommendations = await _api.getRecommendations(limit: 12);
      featured = recommendations.contentBased.map((r) => r.book).toList();
      popular = recommendations.popular.map((r) => r.book).toList();
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query, {int? genreId, int? bookCategoryId}) async {
    _lastSearch = query.trim();
    if (genreId != null) {
      _genreId = genreId;
    }
    if (bookCategoryId != null) {
      _bookCategoryId = bookCategoryId;
    }
    isSearching = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.searchBooks(
        search: _lastSearch.isEmpty ? null : _lastSearch,
        genreId: _genreId,
        bookCategoryId: _bookCategoryId,
        pageSize: 50,
      );
      searchResults = result.items;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      searchResults = [];
    }

    isSearching = false;
    notifyListeners();
  }

  void applyFilters({int? genreId, int? bookCategoryId}) {
    _genreId = genreId;
    _bookCategoryId = bookCategoryId;
    search(_lastSearch);
  }

  Future<void> loadBookDetail(int bookId) async {
    isLoading = true;
    errorMessage = null;
    selectedBook = null;
    availability = null;
    notifyListeners();

    try {
      selectedBook = await _api.getBook(bookId);
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailability(
    int bookCopyId,
    DateTime month,
  ) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    try {
      availability = await _api.getAvailability(bookCopyId, from, to);
      notifyListeners();
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      notifyListeners();
    }
  }

  bool isDayOccupied(DateTime day) {
    if (availability == null) {
      return false;
    }
    final normalized = DateTime(day.year, day.month, day.day);
    for (final period in availability!.occupiedPeriods) {
      final start = DateTime(
        period.fromDate.year,
        period.fromDate.month,
        period.fromDate.day,
      );
      final end = DateTime(
        period.toDate.year,
        period.toDate.month,
        period.toDate.day,
      );
      if (!normalized.isBefore(start) && !normalized.isAfter(end)) {
        return true;
      }
    }
    return false;
  }

  void clearSelection() {
    selectedBook = null;
    availability = null;
    notifyListeners();
  }
}
