class DomainResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  DomainResult.success(this.data)
      : success = true,
        errorMessage = null;

  DomainResult.failure(this.errorMessage)
      : success = false,
        data = null;

  DomainResult({
    required this.success,
    this.data,
    this.errorMessage,
  });

  bool get isFailure => !success;
  bool get hasData => data != null;
}
