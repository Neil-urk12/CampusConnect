/// Base exception for resource domain errors
class ResourceException implements Exception {
  final String code;
  final String message;

  const ResourceException({
    this.code = 'resource-error',
    this.message = '',
  });

  @override
  String toString() =>
      'ResourceException($code)${message.isNotEmpty ? ': $message' : ''}';
}

/// Validation errors (missing fields, invalid values)
class ResourceValidationException extends ResourceException {
  final String? field;

  const ResourceValidationException({
    String message = '',
    this.field,
  }) : super(code: 'validation-error', message: message);
}

/// Network / Firestore errors
class ResourceNetworkException extends ResourceException {
  const ResourceNetworkException({String message = ''})
      : super(code: 'network-error', message: message);
}

/// Appwrite storage errors
class ResourceStorageException extends ResourceException {
  const ResourceStorageException({String message = ''})
      : super(code: 'storage-error', message: message);
}

/// Permission denied errors
class ResourcePermissionException extends ResourceException {
  const ResourcePermissionException({String message = ''})
      : super(code: 'permission-denied', message: message);
}

/// Resource not found
class ResourceNotFoundException extends ResourceException {
  const ResourceNotFoundException({String message = ''})
      : super(code: 'not-found', message: message);
}
