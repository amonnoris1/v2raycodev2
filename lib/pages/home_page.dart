// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigate; // Callback to navigate to a specific tab

  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final bypassSubnetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch IP and location at startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchIpAndLocation();
    });
  }

  @override
  void dispose() {
    bypassSubnetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const SizedBox(height: 5),
          // Location and IP Address Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: appState.country,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(
                        text: '\nYour location',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: appState.currentIp,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(
                        text: '\nIP Address',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Protocol and Network Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'V2Ray',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextSpan(
                        text: '\nProtocol in use',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appState.network,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Selected Configuration Display
          ListTile(
            title: Text(
              appState.selectedConfig != null
                  ? appState.selectedConfig!.name
                  : 'No configuration selected',
            ),
            subtitle: Text(
              appState.selectedConfig?.remark ??
                  'Please select a configuration.',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.manage_accounts),
              onPressed: () {
                // Navigate to Servers (Configurations) tab using the callback
                widget.onNavigate(1); // Index 1 corresponds to Servers
              },
            ),
          ),
          const SizedBox(height: 10),
          // Connect/Disconnect Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed:
                    appState.isConnected ? null : () => appState.connect(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Connect'),
              ),
              ElevatedButton(
                onPressed:
                    appState.isConnected ? () => appState.disconnect() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Disconnect'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Server Delay Button
          ElevatedButton(
            onPressed: () => appState.delay(),
            child: const Text('Server Delay'),
          ),
          const SizedBox(height: 20),
          // Real-Time Statistics
          ValueListenableBuilder<V2RayStatus>(
            valueListenable: appState.v2rayStatus,
            builder: (context, value, child) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  // Show the remaining time if connected
                  if (appState.isConnected)
                    Text(
                      'Time remaining: ${_formatTime(appState.remainingTime)}',
                      style: const TextStyle(fontSize: 24),
                    ),
                  const SizedBox(height: 10),
                  // Display connection state
                  Text(
                    'State: ${appState.v2rayStatus.value.state}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  // Display connection duration
                  Text(
                    'Duration: ${appState.v2rayStatus.value.duration}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  // Display upload and download speeds
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Speed:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(
                        '${_formatSpeed(appState.v2rayStatus.value.uploadSpeed)} ↑',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_formatSpeed(appState.v2rayStatus.value.downloadSpeed)} ↓',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Display total data uploaded and downloaded
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Data Used:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(
                        '${_formatBytes(appState.v2rayStatus.value.upload)} ↑',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_formatBytes(appState.v2rayStatus.value.download)} ↓',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Display latency
                  Text(
                    'Latency: ${appState.latency > 0 ? '${appState.latency} ms' : 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  // Display core version
                  Text(
                    'Core Version: ${appState.coreVersion ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper method to format Duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  // Helper method to format remaining time
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper method to format speed
  String _formatSpeed(int speed) {
    // Convert bytes per second to kbps or Mbps
    double kbps = speed / 1000;
    if (kbps >= 1000) {
      double mbps = kbps / 1000;
      return '${mbps.toStringAsFixed(2)} Mbps';
    }
    return '${kbps.toStringAsFixed(2)} kbps';
  }

  // Helper method to format bytes
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(2)} KB';
    double mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(2)} MB';
    double gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
