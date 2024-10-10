// lib/models/v2ray_config.dart

import 'dart:convert';

class V2RayConfig {
  final String name;
  final String configText;
  final String remark;

  V2RayConfig({
    required this.name,
    required this.configText,
    required this.remark,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'configText': configText,
        'remark': remark,
      };

  factory V2RayConfig.fromJson(Map<String, dynamic> json) {
    return V2RayConfig(
      name: json['name'],
      configText: json['configText'],
      remark: json['remark'],
    );
  }

  // For encoding/decoding to/from JSON strings
  String encode() => jsonEncode(toJson());

  static V2RayConfig decode(String jsonString) =>
      V2RayConfig.fromJson(jsonDecode(jsonString));
}
