/// Consolidated exception for all chat-domain errors.
///
/// Replaces the previous 4-class hierarchy (ChatNotFoundException,
/// ChatPermissionException, ChatValidationException, ChatNetworkException).
/// Callers catch a single [ChatException] and dispatch on [code].
class ChatException implements Exception {
  final String code;
  final String message;
  final dynamic originalError;

  const ChatException({
    this.code = 'unexpected',
    this.message = '',
    this.originalError,
  });

  // ── Error codes ──────────────────────────────────────────────────────
  static const String chatNotFound = 'chat-not-found';
  static const String permissionDenied = 'permission-denied';
  static const String validationError = 'validation-error';
  static const String networkError = 'network-error';

  @override
  String toString() =>
      'ChatException($code)${message.isNotEmpty ? ': $message' : ''}';
}
