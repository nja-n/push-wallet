import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_cubit.dart';
import '../../../security/presentation/pages/security_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencies = {
      '\$': 'Dollar (\$)',
      '€': 'Euro (€)',
      '₹': 'Rupee (₹)',
      '£': 'Pound (£)',
      '¥': 'Yen (¥)',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'General',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),

          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security, color: Colors.red),
              ),
              title: const Text('Security'),
              subtitle: const Text('App Lock & PIN'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SecuritySettingsPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_exchange,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Currency'),
              subtitle: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  if (state is SettingsLoaded) {
                    final symbol = state.currencySymbol;
                    return Text(currencies[symbol] ?? symbol);
                  }
                  return const Text('');
                },
              ),
              onTap: () => _showCurrencyPicker(context, currencies),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final loaded = state as SettingsLoaded;
              return Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto Backup'),
                      subtitle: const Text(
                        'Backup data on changes (Simulated)',
                      ),
                      value: loaded.autoBackup,
                      onChanged: (val) {
                        context.read<SettingsCubit>().toggleAutoBackup(val);
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.backup,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Colors.green,
                        ),
                      ),
                      title: const Text('Backup Data'),
                      subtitle: Text(
                        loaded.lastBackup != null
                            ? 'Last: ${_formatDate(loaded.lastBackup!)}'
                            : 'No backup yet',
                      ),
                      onTap: () async {
                        await context.read<SettingsCubit>().createBackup(
                          context,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download, color: Colors.orange),
                      ),
                      title: const Text('Restore Data'),
                      subtitle: const Text('Import from backup file'),
                      onTap: () async {
                        final success = await context
                            .read<SettingsCubit>()
                            .restoreBackup();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Data restored successfully!'
                                    : 'Restore cancelled or failed.',
                              ),
                            ),
                          );
                          if (success) {
                            // Ideally trigger a full app reload or re-fetch blocs
                            // For now, simple re-fetch of accounts/transactions if possible
                            // But since Blocs might hold old state, a full reload is safer
                            // Or we can emit events to reload data.
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _showCurrencyPicker(
    BuildContext context,
    Map<String, String> currencies,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Currency',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            ...currencies.entries.map(
              (e) => ListTile(
                title: Text(e.value),
                onTap: () {
                  context.read<SettingsCubit>().updateCurrency(e.key);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
