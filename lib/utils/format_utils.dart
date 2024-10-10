// lib/utils/format_utils.dart

String formatBytes(int bytes) {
  const int KB = 1024;
  const int MB = KB * 1024;
  const int GB = MB * 1024;

  if (bytes >= GB) {
    return '${(bytes / GB).toStringAsFixed(2)} GB';
  } else if (bytes >= MB) {
    return '${(bytes / MB).toStringAsFixed(2)} MB';
  } else if (bytes >= KB) {
    return '${(bytes / KB).toStringAsFixed(2)} KB';
  } else {
    return '$bytes B';
  }
}

String formatSpeed(int bytesPerSecond) {
  return '${formatBytes(bytesPerSecond)}/s';
}
