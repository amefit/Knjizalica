import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class ReferenceDataProvider extends ChangeNotifier {
  ReferenceDataProvider(this._api);

  final ApiService _api;

  List<Country> countries = [];
  List<City> cities = [];
  List<LookupItem> genres = [];
  List<LookupItem> bookCategories = [];
  List<LookupItem> languages = [];
  List<LookupItem> publishers = [];

  bool isLoading = false;
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.getCountries(),
        _api.getCities(),
        _api.getGenres(),
        _api.getBookCategories(),
        _api.getLanguages(),
        _api.getPublishers(),
      ]);
      countries = results[0] as List<Country>;
      cities = results[1] as List<City>;
      genres = results[2] as List<LookupItem>;
      bookCategories = results[3] as List<LookupItem>;
      languages = results[4] as List<LookupItem>;
      publishers = results[5] as List<LookupItem>;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load reference data.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveLookup({
    required String type,
    int? id,
    required String name,
    int? countryId,
  }) async {
    try {
      switch (type) {
        case 'country':
          if (id == null) {
            await _api.createCountry(name);
          } else {
            await _api.updateCountry(id, name);
          }
        case 'city':
          if (countryId == null) throw ApiException('Country is required.');
          if (id == null) {
            await _api.createCity(name, countryId);
          } else {
            await _api.updateCity(id, name, countryId);
          }
        case 'genre':
          if (id == null) {
            await _api.createGenre(name);
          } else {
            await _api.updateGenre(id, name);
          }
        case 'category':
          if (id == null) {
            await _api.createBookCategory(name);
          } else {
            await _api.updateBookCategory(id, name);
          }
        case 'language':
          if (id == null) {
            await _api.createLanguage(name);
          } else {
            await _api.updateLanguage(id, name);
          }
        case 'publisher':
          if (id == null) {
            await _api.createPublisher(name);
          } else {
            await _api.updatePublisher(id, name);
          }
      }
      await loadAll();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to save item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLookup(String type, int id) async {
    try {
      switch (type) {
        case 'country':
          await _api.deleteCountry(id);
        case 'city':
          await _api.deleteCity(id);
        case 'genre':
          await _api.deleteGenre(id);
        case 'category':
          await _api.deleteBookCategory(id);
        case 'language':
          await _api.deleteLanguage(id);
        case 'publisher':
          await _api.deletePublisher(id);
      }
      await loadAll();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Failed to delete item.';
      notifyListeners();
      return false;
    }
  }
}
