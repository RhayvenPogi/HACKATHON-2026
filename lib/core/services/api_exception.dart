sealed class ApiException implements Exception {
  const ApiException(this.userMessage);

  /// Safe to show to users. Contains no assessment data.
  final String userMessage;

  @override
  String toString() => '$runtimeType: $userMessage';
}

class NetworkException extends ApiException {
  const NetworkException()
      : super('Could not connect to the server. Check your connection '
            'and try again.');
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException()
      : super('The server took too long to respond. Please try again.');
}

class ValidationException extends ApiException {
  const ValidationException([this.details = const []])
      : super('The server could not accept this request. Please review it '
            'and try again.');

  /// Field messages from the server, e.g. password rules.
  final List<String> details;

  String get displayMessage => details.isEmpty ? userMessage : details.join('\n');
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super('Your session has ended. Please sign in again.');
}

class ForbiddenException extends ApiException {
  const ForbiddenException() : super('You are not allowed to do this yet.');
}

class ServerException extends ApiException {
  const ServerException(this.statusCode)
      : super('The server had a problem processing your request. '
            'Please try again later.');

  final int statusCode;
}

class InvalidResponseException extends ApiException {
  const InvalidResponseException()
      : super('The server sent an unexpected response. Please try again '
            'later.');
}