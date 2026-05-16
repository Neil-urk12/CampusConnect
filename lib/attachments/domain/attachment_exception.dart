class AttachmentException implements Exception {
  const AttachmentException({
    required this.code,
    required this.message,
    this.field,
    this.cause,
  });

  final AttachmentErrorCode code;
  final String message;
  final String? field;
  final Object? cause;

  @override
  String toString() => 'AttachmentException(${code.name}): $message';
}

enum AttachmentErrorCode {
  invalidOwner,
  unsupportedType,
  fileTooLarge,
  uploadFailed,
}
