import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

enum MemberTab { all, active, blocked }

class MembersProvider extends ChangeNotifier {
  MembersProvider(this._api);

  final ApiService _api;

  List<Member> members = [];
  int totalCount = 0;
  int page = 1;
  int pageSize = 20;
  String search = '';
  MemberTab currentTab = MemberTab.all;
  bool isLoading = false;
  String? error;

  Future<void> loadMembers({int? pageOverride, MemberTab? tab}) async {
    if (pageOverride != null) page = pageOverride;
    if (tab != null) currentTab = tab;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      String? tabParam;
      switch (currentTab) {
        case MemberTab.active:
          tabParam = 'active';
        case MemberTab.blocked:
          tabParam = 'blocked';
        case MemberTab.all:
          tabParam = null;
      }

      final result = await _api.getMembers(
        page: page,
        pageSize: pageSize,
        search: search.isEmpty ? null : search,
        tab: tabParam,
      );
      members = result.items;
      totalCount = result.totalCount;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load members.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> blockMember(int id) async {
    try {
      await _api.blockMember(id);
      await loadMembers();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to block member.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> unblockMember(int id) async {
    try {
      await _api.unblockMember(id);
      await loadMembers();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to unblock member.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMember(Map<String, dynamic> body) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _api.createMember(body);
      await loadMembers();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Failed to create member.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMember(int id, Map<String, dynamic> body) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _api.updateMember(id, body);
      await loadMembers();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Failed to update member.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMember(int id) async {
    try {
      await _api.deleteMember(id);
      await loadMembers();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to delete member.';
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
    await loadMembers();
  }
}

class ActivityLogsProvider extends ChangeNotifier {
  ActivityLogsProvider(this._api);

  final ApiService _api;

  List<ActivityLog> logs = [];
  int totalCount = 0;
  int page = 1;
  int pageSize = 20;
  String search = '';
  bool isLoading = false;
  String? error;

  Future<void> loadLogs({int? pageOverride}) async {
    if (pageOverride != null) page = pageOverride;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _api.getActivityLogs(
        page: page,
        pageSize: pageSize,
        search: search.isEmpty ? null : search,
      );
      logs = result.items;
      totalCount = result.totalCount;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load activity logs.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    search = value;
    page = 1;
  }

  Future<void> applySearch(String value) async {
    setSearch(value);
    await loadLogs();
  }
}
