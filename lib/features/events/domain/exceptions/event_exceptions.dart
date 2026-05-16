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
  EventValidationException(super.message, {super.code = 'validation-error'});
}

class EventPermissionException extends EventException {
  EventPermissionException(super.message, {super.code = 'permission-denied'});
}

class EventNetworkException extends EventException {
  EventNetworkException(super.message, {super.code = 'network-error'});
}

class EventRsvpException extends EventException {
  EventRsvpException(super.message, {super.code = 'rsvp-error'});
}
