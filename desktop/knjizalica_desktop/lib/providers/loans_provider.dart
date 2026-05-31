import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

enum LoanTab { active, overdue, history }

class LoansProvider extends ChangeNotifier {
  LoansProvider(this._api);

  final ApiService _api;

  List<Loan> loans = [];
  int totalCount = 0;
  int page = 1;
  int pageSize = 20;
  String search = '';
  LoanTab currentTab = LoanTab.active;
  bool isLoading = false;
  String? error;

  Future<void> loadLoans({int? pageOverride, LoanTab? tab}) async {
    if (pageOverride != null) page = pageOverride;
    if (tab != null) currentTab = tab;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      PagedResult<Loan> result;

      switch (currentTab) {
        case LoanTab.overdue:
          result = await _api.getOverdueLoans(
            page: page,
            pageSize: pageSize,
            search: search.isEmpty ? null : search,
          );
        case LoanTab.history:
          final completed = await _api.getLoans(
            page: page,
            pageSize: pageSize,
            search: search.isEmpty ? null : search,
            status: 'Completed',
          );
          final cancelled = await _api.getLoans(
            page: 1,
            pageSize: pageSize,
            search: search.isEmpty ? null : search,
            status: 'Cancelled',
          );
          final merged = [...completed.items, ...cancelled.items];
          merged.sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));
          loans = merged;
          totalCount = completed.totalCount + cancelled.totalCount;
          isLoading = false;
          notifyListeners();
          return;
        case LoanTab.active:
          final pending = await _api.getLoans(
            page: 1,
            pageSize: 100,
            status: 'Pending',
            search: search.isEmpty ? null : search,
          );
          final confirmed = await _api.getLoans(
            page: 1,
            pageSize: 100,
            status: 'Confirmed',
            search: search.isEmpty ? null : search,
          );
          final overdue = await _api.getOverdueLoans(
            page: 1,
            pageSize: 100,
            search: search.isEmpty ? null : search,
          );
          final merged = [...pending.items, ...confirmed.items, ...overdue.items];
          final seen = <int>{};
          final unique = <Loan>[];
          for (final loan in merged) {
            if (seen.add(loan.id)) unique.add(loan);
          }
          unique.sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));
          final start = (page - 1) * pageSize;
          loans = unique.skip(start).take(pageSize).toList();
          totalCount = unique.length;
          isLoading = false;
          notifyListeners();
          return;
      }

      loans = result.items;
      totalCount = result.totalCount;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load loans.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLoan({
    required int memberProfileId,
    required int bookCopyId,
    required DateTime dueDate,
    String? notes,
  }) async {
    try {
      await _api.createLoan({
        'memberProfileId': memberProfileId,
        'bookCopyId': bookCopyId,
        'dueDate': dueDate.toUtc().toIso8601String(),
        'notes': notes,
      });
      await loadLoans(pageOverride: 1);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to create loan.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmLoan(int id) async {
    try {
      await _api.confirmLoan(id);
      await loadLoans();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to confirm loan.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> returnLoan(int id) async {
    try {
      await _api.returnLoan(id);
      await loadLoans();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to return loan.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelLoan(int id, {String? reason}) async {
    try {
      await _api.cancelLoan(id, reason: reason);
      await loadLoans();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to cancel loan.';
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
    await loadLoans();
  }
}
