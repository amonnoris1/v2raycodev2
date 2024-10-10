// lib/models/connection_log.dart

class ConnectionLog {
  final String serverName;
  final DateTime startTime;
  Duration duration;
  final int dataUploaded; // in bytes
  final int dataDownloaded; // in bytes

  ConnectionLog({
    required this.serverName,
    required this.startTime,
    required this.duration,
    required this.dataUploaded,
    required this.dataDownloaded,
  });

  // Convert a ConnectionLog into a Map.
  Map<String, dynamic> toJson() => {
        'serverName': serverName,
        'startTime': startTime.toIso8601String(),
        'duration': duration.inSeconds,
        'dataUploaded': dataUploaded,
        'dataDownloaded': dataDownloaded,
      };

  // Create a ConnectionLog from a Map.
  factory ConnectionLog.fromJson(Map<String, dynamic> json) => ConnectionLog(
        serverName: json['serverName'],
        startTime: DateTime.parse(json['startTime']),
        duration: Duration(seconds: json['duration']),
        dataUploaded: json['dataUploaded'],
        dataDownloaded: json['dataDownloaded'],
      );
}
