import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class BooksProvider extends ChangeNotifier {
  BooksProvider(this._api);

  final ApiService _api;

  List<BookListItem> books = [];
  BookDetail? selectedBook;
  int totalCount = 0;
  int page = 1;
  int pageSize = 20;
  String search = '';
  bool isLoading = false;
  String? error;

  Future<void> loadBooks({int? pageOverride}) async {
    if (pageOverride != null) page = pageOverride;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _api.getBooks(
        page: page,
        pageSize: pageSize,
        search: search.isEmpty ? null : search,
      );
      books = result.items;
      totalCount = result.totalCount;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load books.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<BookDetail?> loadBook(int id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      selectedBook = await _api.getBook(id);
      return selectedBook;
    } on ApiException catch (e) {
      error = e.message;
      return null;
    } catch (_) {
      error = 'Failed to load book details.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveBook({
    int? id,
    required String title,
    String? edition,
    String? description,
    String? coverImagePath,
    required int genreId,
    required int bookCategoryId,
    required int languageId,
    required int publisherId,
    required List<int> authorIds,
    int copyCount = 1,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      if (id == null) {
        await _api.createBook({
          'title': title,
          'edition': edition,
          'description': description,
          'coverImagePath': coverImagePath,
          'genreId': genreId,
          'bookCategoryId': bookCategoryId,
          'languageId': languageId,
          'publisherId': publisherId,
          'authorIds': authorIds,
          'copyCount': copyCount,
        });
      } else {
        await _api.updateBook(id, {
          'title': title,
          'edition': edition,
          'description': description,
          'coverImagePath': coverImagePath,
          'genreId': genreId,
          'bookCategoryId': bookCategoryId,
          'languageId': languageId,
          'publisherId': publisherId,
          'authorIds': authorIds,
          'copyCount': copyCount,
        });
      }
      await loadBooks();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Failed to save book.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBook(int id) async {
    try {
      await _api.deleteBook(id);
      await loadBooks();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to delete book.';
      notifyListeners();
      return false;
    }
  }

  void setSearch(String value) {
    search = value;
    page = 1;
  }

  Future<void> applySearch(String value) async {
    setSearch(value);
    await loadBooks();
  }
}

class AuthorsProvider extends ChangeNotifier {
  AuthorsProvider(this._api);

  final ApiService _api;

  List<Author> authors = [];
  bool isLoading = false;
  String? error;

  Future<void> loadAuthors() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      authors = await _api.getAuthors();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load authors.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveAuthor({
    int? id,
    required String firstName,
    required String lastName,
    String? biography,
  }) async {
    try {
      final body = {
        'firstName': firstName,
        'lastName': lastName,
        'biography': biography,
      };
      if (id == null) {
        await _api.createAuthor(body);
      } else {
        await _api.updateAuthor(id, body);
      }
      await loadAuthors();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to save author.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAuthor(int id) async {
    try {
      await _api.deleteAuthor(id);
      await loadAuthors();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to delete author.';
      notifyListeners();
      return false;
    }
  }
}
