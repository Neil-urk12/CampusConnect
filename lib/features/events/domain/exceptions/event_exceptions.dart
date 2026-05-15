class EventException implements Exception {
  final String message;
  final String? code;

  EventException(this.message, {this.code});

  @override
  String toString() =>
      'EventException: $message${code != null ? ' (code: $code)' : ''}';
}

class EventNotFoundException extends EventException {
  EventNotFoundException(String eventId)
    : super('Event not found: $eventId', code: 'event-not-found');
}

class EventValidationException extends EventException {
  EventValidationException(String message)
    : super(message, code: 'validation-error');
}

class EventPermissionException extends EventException {
  EventPermissionException(String message)
    : super(message, code: 'permission-denied');
}

class EventNetworkException extends EventException {
  EventNetworkException(String message) : super(message, code: 'network-error');
}
