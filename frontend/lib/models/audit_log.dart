class AuditLog {
  final int? id;
  final String? eventTime;
  final String? level;
  final String? eventType;
  final int? userId;
  final String? module;
  final String? result;
  final String? message;

  AuditLog({
    this.id,
    this.eventTime,
    this.level,
    this.eventType,
    this.userId,
    this.module,
    this.result,
    this.message,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['logId'],
      eventTime: json['eventTime'],
      level: json['level'],
      eventType: json['eventType'],
      userId: json['userId'],
      module: json['module'],
      result: json['result'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'logId': id,
      'eventTime': eventTime,
      'level': level,
      'eventType': eventType,
      'userId': userId,
      'module': module,
      'result': result,
      'message': message,
    };
  }
}
