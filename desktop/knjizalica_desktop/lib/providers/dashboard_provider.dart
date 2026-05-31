import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._api);

  final ApiService _api;

  DashboardData? data;
  List<Reservation> recentReservations = [];
  bool isLoading = false;
  String? error;
  final Set<int> _confirmingReservationIds = {};

  Set<int> get confirmingReservationIds => Set.unmodifiable(_confirmingReservationIds);

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      data = await _api.getDashboard();
      await _loadPendingReservations();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load dashboard data.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPendingReservations() async {
    final reservations = await _api.getReservations(
      page: 1,
      pageSize: 8,
      status: 'Pending',
    );
    recentReservations = reservations.items;
  }

  Future<void> confirmReservation(int id) async {
    if (_confirmingReservationIds.contains(id)) {
      return;
    }

    _confirmingReservationIds.add(id);
    notifyListeners();

    try {
      await _api.confirmReservation(id);
      recentReservations = recentReservations.where((r) => r.id != id).toList();
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      error = 'Failed to confirm reservation.';
      notifyListeners();
      rethrow;
    } finally {
      _confirmingReservationIds.remove(id);
      notifyListeners();
    }
  }
}
