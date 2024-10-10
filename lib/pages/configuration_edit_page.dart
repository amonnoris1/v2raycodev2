// lib/pages/configuration_edit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart'; // Import FlutterV2ray
import 'package:provider/provider.dart';
import '../models/v2ray_config.dart';
import '../providers/app_state.dart';

class ConfigurationEditPage extends StatefulWidget {
  final V2RayConfig? config;

  const ConfigurationEditPage({this.config, Key? key}) : super(key: key);

  @override
  _ConfigurationEditPageState createState() => _ConfigurationEditPageState();
}

class _ConfigurationEditPageState extends State<ConfigurationEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _remarkController;
  late TextEditingController _configTextController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');
    _remarkController =
        TextEditingController(text: widget.config?.remark ?? '');
    _configTextController =
        TextEditingController(text: widget.config?.configText ?? '');
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState?.validate() ?? false) {
      final newConfig = V2RayConfig(
        name: _nameController.text.trim(),
        remark: _remarkController.text.trim(),
        configText: _configTextController.text.trim(),
      );
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.addConfig(newConfig);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    _configTextController.dispose();
    super.dispose();
  }

  void importConfigFromClipboard() async {
    if (await Clipboard.hasStrings()) {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null) {
        final String content = clipboardData.text?.trim() ?? '';
        try {
          if (content.startsWith('vless://') ||
              content.startsWith('vmess://') ||
              content.startsWith('trojan://')) {
            // It's a V2Ray share link
            final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(content);
            final String jsonConfig = v2rayURL.getFullConfiguration();

            // Update the controllers with parsed data
            setState(() {
              _nameController.text = v2rayURL.remark.isNotEmpty
                  ? v2rayURL.remark
                  : '${v2rayURL.address}:${v2rayURL.port}';
              _remarkController.text = v2rayURL.remark;
              _configTextController.text = jsonConfig;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuration imported successfully.'),
              ),
            );
          } else {
            // Assume it's JSON configuration
            setState(() {
              _configTextController.text = content;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuration imported as JSON.'),
              ),
            );
          }
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error importing configuration: $error'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.config != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Configuration' : 'Add Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Configuration Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a configuration name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(labelText: 'Remark'),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextFormField(
                  controller: _configTextController,
                  decoration: const InputDecoration(
                    labelText: 'Configuration Text (JSON format)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Configuration text cannot be empty.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveConfig,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: importConfigFromClipboard,
                    child: const Text('Import from Clipboard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
