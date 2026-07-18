import 'dart:io';
import 'package:dio/dio.dart';

/// Turns any thrown error into a message that is safe and helpful to show a
/// person — never the raw exception, which for Dio includes the request URL,
/// status line and response body (all internal detail we don't want on screen).
///
/// The backend reports field problems as `{ message: "Validation failed",
/// errors: [...] }`; the useful part is `errors`, so it is read first.
String apiErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Please check your connection and try again.';
      case DioExceptionType.badCertificate:
        return 'Could not establish a secure connection.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'Cannot reach the server. Please check your connection and try again.';
        }
        final status = error.response?.statusCode ?? 0;
        final fromBody = _messageFromBody(error.response?.data);
        if (fromBody != null) return fromBody;
        return _statusMessage(status, fallback);
    }
  }
  return fallback;
}

/// Reads a friendly message out of the backend error envelope, if present.
String? _messageFromBody(dynamic data) {
  if (data is Map) {
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors
          .map((e) => e is Map ? (e['message'] ?? e).toString() : e.toString())
          .join('\n');
    }
    final msg = data['message'] ?? data['error'];
    if (msg is List && msg.isNotEmpty) return msg.join('\n');
    if (msg is String && msg.isNotEmpty && msg.toLowerCase() != 'validation failed') {
      return msg;
    }
  }
  return null;
}

String _statusMessage(int status, String fallback) {
  switch (status) {
    case 400:
      return 'Some details are invalid. Please check and try again.';
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return "You don't have permission to do that.";
    case 404:
      return "We couldn't find what you were looking for.";
    case 409:
      return 'That conflicts with something that already exists.';
    case 429:
      return 'Too many attempts. Please wait a moment and try again.';
    default:
      return status >= 500
          ? 'The server is having a problem right now. Please try again shortly.'
          : fallback;
  }
}
