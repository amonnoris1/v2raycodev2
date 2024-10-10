// lib/pages/connection_history_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/connection_log.dart';
import '../utils/format_utils.dart';

class ConnectionHistoryPage extends StatelessWidget {
  const ConnectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final List<ConnectionLog> logs =
        appState.connectionLogs.reversed.toList(); // Show latest first

    return Column(
      children: [
        // Clear History Button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              _confirmClearHistory(context, appState);
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ),
        Expanded(
          child: logs.isNotEmpty
              ? ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    ConnectionLog log = logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(log.serverName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Connected at: ${log.startTime.toLocal()}'),
                            Text('Duration: ${formatDuration(log.duration)}'),
                            Text(
                                'Data Uploaded: ${formatBytes(log.dataUploaded)}'),
                            Text(
                                'Data Downloaded: ${formatBytes(log.dataDownloaded)}'),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text(
                    'No connection history available.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
        ),
      ],
    );
  }

  void _confirmClearHistory(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Connection History'),
          content: const Text(
              'Are you sure you want to clear all connection history?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () {
                appState.clearConnectionLogs();
                Navigator.of(context).pop(); // Dismiss the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connection history cleared.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
