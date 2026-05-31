import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pagination_models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String parseApiError(http.Response response) {
  try {
    final dynamic body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      if (body['message'] is String && (body['message'] as String).isNotEmpty) {
        return body['message'] as String;
      }

      final errors = body['errors'];
      if (errors is Map<String, dynamic>) {
        final messages = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else {
            messages.add(value.toString());
          }
        }
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      final errorResponse = ErrorResponse.fromJson(body);
      if (errorResponse.message.isNotEmpty) {
        return errorResponse.message;
      }
    }
  } catch (_) {
    // Fall through to generic message.
  }

  if (response.statusCode == 401) {
    return 'Session expired. Please sign in again.';
  }

  return 'Request failed (${response.statusCode})';
}

void throwIfNotSuccess(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  }
  throw ApiException(parseApiError(response), statusCode: response.statusCode);
}
