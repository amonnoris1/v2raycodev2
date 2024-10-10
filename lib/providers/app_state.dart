// lib/providers/app_state.dart

import 'package:flutter/material.dart';
import '../models/v2ray_config.dart';
import '../models/connection_log.dart';
import '../utils/storage_helper.dart';
import 'dart:async';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppState extends ChangeNotifier {
  // **VPN Configuration Management**
  List<V2RayConfig> _configs = [];
  V2RayConfig? _selectedConfig;
  List<ConnectionLog> _connectionLogs = [];

  List<V2RayConfig> get configs => _configs;
  V2RayConfig? get selectedConfig => _selectedConfig;
  List<ConnectionLog> get connectionLogs => _connectionLogs;

  AppState() {
    loadConfigs();
    loadConnectionLogs();
    initializeV2Ray();
  }

  // Load VPN configurations from storage
  Future<void> loadConfigs() async {
    _configs = await StorageHelper.loadConfigs();
    notifyListeners();
  }

  // Add a new VPN configuration
  Future<void> addConfig(V2RayConfig config) async {
    _configs.add(config);
    await StorageHelper.saveConfig(config);
    notifyListeners();
  }

  // Select a VPN configuration
  void selectConfig(V2RayConfig config) {
    _selectedConfig = config;
    notifyListeners();
  }

  // Delete a VPN configuration
  Future<void> deleteConfig(V2RayConfig config) async {
    _configs.remove(config);
    await StorageHelper.deleteConfig(config.name);
    notifyListeners();
  }

  // **Connection Log Management**

  // Load connection logs from storage
  Future<void> loadConnectionLogs() async {
    _connectionLogs = await StorageHelper.loadLogs();
    notifyListeners();
  }

  // Add a new connection log
  Future<void> addConnectionLog(ConnectionLog log) async {
    _connectionLogs.add(log);
    await StorageHelper.saveLog(log);
    notifyListeners();
  }

  // Update the last connection log with duration and data usage
  Future<void> updateLastConnectionLog(
      Duration duration, int uploaded, int downloaded) async {
    if (_connectionLogs.isNotEmpty) {
      ConnectionLog lastLog = _connectionLogs.last;
      if (lastLog.duration == Duration.zero) {
        // Option 1: Mutable duration
        lastLog.duration = duration;
        _connectionLogs[_connectionLogs.length - 1] = lastLog;
        await StorageHelper.saveLog(lastLog);

        // Option 2: Immutable duration with copyWith
        /*
        ConnectionLog updatedLog = lastLog.copyWith(duration: duration);
        _connectionLogs[_connectionLogs.length - 1] = updatedLog;
        await StorageHelper.saveLog(updatedLog);
        */

        notifyListeners();
      }
    }
  }

  // Clear all connection logs
  Future<void> clearConnectionLogs() async {
    _connectionLogs.clear();
    await StorageHelper.clearLogs();
    notifyListeners();
  }

  // **VPN Connection and Timer Management**

  // Timer related variables
  bool isConnected = false;
  final int totalDuration = 360; // Total duration in seconds (6 minutes)
  int remainingTime = 360; // Remaining time in seconds
  Timer? timer;
  Timer? latencyTimer;
  int latency = 0;

  // V2Ray instance
  late FlutterV2ray flutterV2ray;

  // V2Ray status notifier
  ValueNotifier<V2RayStatus> v2rayStatus =
      ValueNotifier<V2RayStatus>(V2RayStatus());

  // IP and location variables
  String currentIp = "Fetching IP...";
  String country = "Fetching location...";
  String network = "Fetching network...";
  String? coreVersion;

  // Initialize V2Ray and set up status listener
  void initializeV2Ray() async {
    flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        v2rayStatus.value = status;
        handleConnectionStatus(status);
      },
    );

    try {
      await flutterV2ray.initializeV2Ray();
      coreVersion = await flutterV2ray.getCoreVersion();
      print('V2Ray Core Version: $coreVersion'); // Debug print
      notifyListeners();
    } catch (e) {
      print('Error initializing V2Ray: $e'); // Debug print
    }

    // Start latency updates
    latencyTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      updateLatency();
    });
  }

  // Handle connection status changes
  void handleConnectionStatus(V2RayStatus status) {
    if (status.state == 'CONNECTED' && !isConnected) {
      isConnected = true;
      startTimer();
      fetchIpAndLocation();
      logConnectionStart();
    } else if (status.state == 'DISCONNECTED' && isConnected) {
      isConnected = false;
      pauseTimer();
      fetchIpAndLocation();
      logConnectionEnd();
    }
    notifyListeners();
  }

  // Connect to VPN
  Future<void> connect() async {
    if (_selectedConfig == null || _selectedConfig!.configText.trim().isEmpty) {
      // Handle error: no config selected
      print('No configuration selected');
      // Optionally, notify UI to show a message
      return;
    }

    try {
      if (await flutterV2ray.requestPermission()) {
        flutterV2ray.startV2Ray(
          remark: _selectedConfig!.remark,
          config: _selectedConfig!.configText,
          proxyOnly: false,
          bypassSubnets: [], // Your logic for split tunneling
        );
        print('VPN Connection Initiated'); // Debug
      } else {
        print('Permission Denied for VPN Connection'); // Debug
        // Optionally, notify UI to show a message
      }
    } catch (e) {
      print('Error connecting VPN: $e'); // Debug
      // Optionally, notify UI to show a message
    }
  }

  // Disconnect from VPN
  void disconnect() {
    try {
      flutterV2ray.stopV2Ray();
      print('VPN Disconnected'); // Debug
    } catch (e) {
      print('Error disconnecting VPN: $e'); // Debug
      // Optionally, notify UI to show a message
    }
  }

  // Start the timer
  void startTimer() {
    // If the remainingTime is zero or less, reset to totalDuration
    if (remainingTime <= 0) {
      remainingTime = totalDuration;
    }

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        remainingTime--;
        notifyListeners();
      } else {
        // Time is up, stop V2Ray connection
        disconnect();
        timer.cancel();
        isConnected = false;
        notifyListeners();
      }
    });
  }

  // Pause the timer
  void pauseTimer() {
    timer?.cancel();
    // Do not reset remainingTime
    notifyListeners();
  }

  // Resume the timer
  void resumeTimer() {
    if (remainingTime > 0 && isConnected) {
      startTimer();
    }
  }

  // Stop the timer and reset remainingTime
  void stopTimer() {
    timer?.cancel();
    remainingTime = totalDuration;
    notifyListeners();
  }

  // Update latency
  void updateLatency() async {
    if (isConnected) {
      try {
        latency = await flutterV2ray.getConnectedServerDelay();
      } catch (e) {
        latency = 0;
      }
      notifyListeners();
    }
  }

  // Connection logging functions
  void logConnectionStart() async {
    if (_selectedConfig != null) {
      ConnectionLog log = ConnectionLog(
        serverName: _selectedConfig!.remark,
        startTime: DateTime.now(),
        duration: Duration.zero,
        dataUploaded: 0,
        dataDownloaded: 0,
      );
      _connectionLogs.add(log);
      await StorageHelper.saveLog(log);
      notifyListeners();
    }
  }

  void logConnectionEnd() async {
    if (_connectionLogs.isNotEmpty) {
      ConnectionLog lastLog = _connectionLogs.last;
      if (lastLog.duration == Duration.zero) {
        // Option 1: Mutable duration
        lastLog.duration = Duration(seconds: totalDuration - remainingTime);
        _connectionLogs[_connectionLogs.length - 1] = lastLog;
        await StorageHelper.saveLog(lastLog);

        // Option 2: Immutable duration with copyWith
        /*
        ConnectionLog updatedLog = lastLog.copyWith(
          duration: Duration(seconds: totalDuration - remainingTime),
        );
        _connectionLogs[_connectionLogs.length - 1] = updatedLog;
        await StorageHelper.saveLog(updatedLog);
        */

        notifyListeners();
      }
    }
  }

  // **IP and Location Fetching**

  // Fetch IP and Location
  Future<void> fetchIpAndLocation() async {
    final url = Uri.parse('http://ip-api.com/json/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentIp = data['query'] ?? 'Unknown IP';
        country = data['country'] ?? 'Unknown Location';
        network = data['as'] ?? 'Unknown Network';
        notifyListeners();
      } else {
        throw Exception('Failed to fetch IP');
      }
    } catch (e) {
      currentIp = 'Error fetching IP';
      country = 'Error fetching location';
      network = 'Error fetching network';
      notifyListeners();
      print('Error fetching IP and location: $e');
    }
  }

  // **Server Delay Testing**

  // Server Delay Function
  void delay() async {
    if (_selectedConfig == null || _selectedConfig!.configText.trim().isEmpty) {
      print('No configuration selected for delay test');
      // Optionally, notify UI to show a message
      return;
    }

    try {
      int delayMs = await flutterV2ray.getServerDelay(
          config: _selectedConfig!.configText);
      print('Server Delay: $delayMs ms'); // Debug
      // Optionally, notify UI to show the delay
    } catch (e) {
      print('Error fetching server delay: $e'); // Debug
      // Optionally, notify UI to show a message
    }
  }
}
