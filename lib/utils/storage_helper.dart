// lib/utils/storage_helper.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2ray_config.dart';
import '../models/connection_log.dart';

class StorageHelper {
  static const String configsKey = 'configs';
  static const String logsKey = 'connection_logs'; // Key for connection logs

  // --- VPN Configuration Methods ---

  static Future<void> saveConfig(V2RayConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> configs = prefs.getStringList(configsKey) ?? [];
    configs.add(jsonEncode(config.toJson()));
    await prefs.setStringList(configsKey, configs);
  }

  static Future<List<V2RayConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> configs = prefs.getStringList(configsKey) ?? [];
    return configs.map((e) => V2RayConfig.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> deleteConfig(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> configs = prefs.getStringList(configsKey) ?? [];
    configs.removeWhere((e) {
      final config = V2RayConfig.fromJson(jsonDecode(e));
      return config.name == name;
    });
    await prefs.setStringList(configsKey, configs);
  }

  // --- Connection Log Methods ---

  // Save a new connection log
  static Future<void> saveLog(ConnectionLog log) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(logsKey) ?? [];
    logs.add(jsonEncode(log.toJson()));
    await prefs.setStringList(logsKey, logs);
  }

  // Load all connection logs
  static Future<List<ConnectionLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(logsKey) ?? [];
    return logs.map((e) => ConnectionLog.fromJson(jsonDecode(e))).toList();
  }

  // Clear all connection logs
  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(logsKey);
  }
}
