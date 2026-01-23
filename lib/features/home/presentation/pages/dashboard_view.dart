import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';

import 'package:push_wallet/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:push_wallet/features/settings/presentation/pages/settings_page.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Balance Card
            BlocBuilder<AccountCubit, AccountState>(
              builder: (context, accountState) {
                return BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, settingsState) {
                    final currency = (settingsState is SettingsLoaded)
                        ? settingsState.currencySymbol
                        : '\$';

                    if (accountState is AccountLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (accountState is AccountLoaded) {
                      final total = accountState.accounts.fold(
                        0.0,
                        (sum, item) => item.type == 'Card'
                            ? sum - item.balance
                            : sum + item.balance,
                      );
                      return Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Balance',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$currency${total.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (accountState is AccountError) {
                      return Text(accountState.message);
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TransactionLoaded) {
                  if (state.transactions.isEmpty) {
                    return const Text('No transactions yet.');
                  }
                  return Column(
                    children: state.transactions.take(5).map((t) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            Icons.compare_arrows,
                          ), // Dynamic icon based on category later
                        ),
                        title: Text(t.description),
                        subtitle: Text(t.date.toString().split(' ')[0]),
                        trailing: Text(
                          t.amount.toStringAsFixed(2),
                          style: TextStyle(
                            color: t.type.index == 0
                                ? Colors.green
                                : (t.type.index == 1
                                      ? Colors.red
                                      : Colors.blue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                } else if (state is TransactionError) {
                  return Text(state.message);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
