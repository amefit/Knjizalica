import 'package:flutter/foundation.dart';

import '../models/loan_models.dart';
import '../services/api_service.dart';
import '../utils/api_error_parser.dart';

class LoansProvider extends ChangeNotifier {
  LoansProvider(this._api);

  final ApiService _api;

  List<LoanDto> activeLoans = [];
  List<LoanDto> historyLoans = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadMyLoans() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final activeResult = await _api.getMyLoans(pageSize: 50);
      activeLoans = activeResult.items
          .where((l) => l.isActive && !l.isReturned)
          .toList();

      final historyResult = await _api.getMyLoans(pageSize: 100);
      historyLoans = historyResult.items
          .where((l) => l.isReturned || l.status == 'Cancelled')
          .toList();
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      activeLoans = [];
      historyLoans = [];
    }

    isLoading = false;
    notifyListeners();
  }
}
