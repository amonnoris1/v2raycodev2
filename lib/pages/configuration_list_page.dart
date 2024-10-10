// lib/pages/configuration_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2ray_config.dart';
import '../providers/app_state.dart';
import 'configuration_edit_page.dart';

class ConfigurationListPage extends StatelessWidget {
  final Function(int)?
      onNavigate; // Optional callback to navigate to a specific tab

  const ConfigurationListPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: appState.isConnected
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfigurationEditPage(),
                      ),
                    );
                  },
            tooltip: appState.isConnected
                ? 'Cannot add while connected'
                : 'Add Configuration',
          ),
        ],
      ),
      body: appState.configs.isEmpty
          ? const Center(
              child: Text('No configurations available.'),
            )
          : ListView.builder(
              itemCount: appState.configs.length,
              itemBuilder: (context, index) {
                final config = appState.configs[index];
                final isSelected = config.name == appState.selectedConfig?.name;

                return ListTile(
                  title: Text(config.name),
                  subtitle: Text(config.remark),
                  leading: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined),
                  onTap: appState.isConnected
                      ? null // Disable selection when connected
                      : () {
                          appState.selectConfig(config);
                          if (onNavigate != null) {
                            onNavigate!(0); // Navigate to Home tab
                          } else {
                            Navigator.pop(
                                context); // Fallback to pop if callback not provided
                          }
                        },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: appState.isConnected
                            ? null // Disable edit when connected
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ConfigurationEditPage(config: config),
                                  ),
                                );
                              },
                        tooltip: appState.isConnected
                            ? 'Cannot edit while connected'
                            : 'Edit Configuration',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: appState.isConnected
                            ? null // Disable delete when connected
                            : () async {
                                // Confirm deletion with the user
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete Configuration'),
                                      content: const Text(
                                          'Are you sure you want to delete this configuration?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true) {
                                  await appState.deleteConfig(config);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Configuration deleted'),
                                    ),
                                  );
                                }
                              },
                        tooltip: appState.isConnected
                            ? 'Cannot delete while connected'
                            : 'Delete Configuration',
                      ),
                    ],
                  ),
                  // Optionally, visually indicate disabled state
                  enabled: !appState.isConnected,
                );
              },
            ),
    );
  }
}
