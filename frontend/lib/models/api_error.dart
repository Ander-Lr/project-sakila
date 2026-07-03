class ApiError implements Exception {
  final String? timestamp;
  final int? status;
  final String? error;
  final String? message;
  final String? path;

  ApiError({
    this.timestamp,
    this.status,
    this.error,
    this.message,
    this.path,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      timestamp: json['timestamp'],
      status: json['status'],
      error: json['error'],
      message: json['message'] ?? 'Error desconocido del servidor',
      path: json['path'],
    );
  }

  @override
  String toString() {
    return message ?? error ?? 'Error en la petición API';
  }
}
