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
  const ValidationException()
      : super('The server could not accept these answers. Please review '
            'them and try again.');
}

class ServerException extends ApiException {
  const ServerException(this.statusCode)
      : super('The server had a problem processing your assessment. '
            'Please try again later.');

  final int statusCode;
}

class InvalidResponseException extends ApiException {
  const InvalidResponseException()
      : super('The server sent an unexpected response. Please try again '
            'later.');
}