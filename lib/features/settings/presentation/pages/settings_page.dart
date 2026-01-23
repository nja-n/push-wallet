import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_cubit.dart';

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
                  final symbol = (state as SettingsLoaded).currencySymbol;
                  return Text(currencies[symbol] ?? symbol);
                },
              ),
              onTap: () => _showCurrencyPicker(context, currencies),
            ),
          ),
        ],
      ),
    );
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
