class DeleteAccountResult {
  final bool success;
  final String message;
  final int? statusCode;
  final bool sessionExpired;
  DeleteAccountResult({
    required this.success,
    this.message = '',
    this.statusCode,
    this.sessionExpired = false,
  });
}
