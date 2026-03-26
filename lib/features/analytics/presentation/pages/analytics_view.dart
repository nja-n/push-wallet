import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/core/services/analytics_helper.dart';
import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/category/domain/entities/category_entity.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';

import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';
import 'package:push_wallet/features/transaction/presentation/pages/transactions_view.dart';
import 'package:push_wallet/features/settings/presentation/bloc/settings_cubit.dart';

class AnalyticsView extends StatelessWidget {
  final String? initialAccountId;

  const AnalyticsView({super.key, this.initialAccountId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final currency =
              (settingsState is SettingsLoaded)
                  ? settingsState.currencySymbol
                  : '\$';

          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              return BlocBuilder<AccountCubit, AccountState>(
                builder: (context, accState) {
                  return BlocBuilder<CategoryCubit, CategoryState>(
                    builder: (context, catState) {
                      if (txState is TransactionLoaded &&
                          accState is AccountLoaded &&
                          catState is CategoryLoaded) {
                        var transactions = txState.transactions;
                        if (initialAccountId != null) {
                          transactions = transactions
                              .where((t) => t.accountId == initialAccountId)
                              .toList();
                        }

                        final helper = AnalyticsHelper(
                          transactions: transactions,
                          accounts: accState.accounts,
                          categories: catState.categories,
                        );

                        return DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              const TabBar(
                                tabs: [
                                  Tab(text: 'Expense'),
                                  Tab(text: 'Income'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _ExpenseTab(
                                      helper: helper,
                                      currency: currency,
                                    ),
                                    _IncomeTab(
                                      helper: helper,
                                      currency: currency,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ExpenseTab extends StatelessWidget {
  final AnalyticsHelper helper;
  final String currency;
  const _ExpenseTab({required this.helper, required this.currency});

  @override
  Widget build(BuildContext context) {
    final categoryExpenses = helper.categoryExpenses;
    final accountExpenses = helper.accountExpenses;

    if (categoryExpenses.isEmpty && accountExpenses.isEmpty) {
      return const Center(child: Text('No expense data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChart(context, categoryExpenses),
          const SizedBox(height: 24),
          Text('By Category', style: Theme.of(context).textTheme.titleLarge),
          ...categoryExpenses.entries.map(
            (e) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(e.key.color),
                child: Text(
                  e.key.icon,
                  style: const TextStyle(fontFamily: 'MaterialIcons'),
                ),
              ),
              title: Text(e.key.name),
              trailing: Text('$currency${e.value.toStringAsFixed(2)}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => TransactionsView(initialCategoryId: e.key.id),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('By Account', style: Theme.of(context).textTheme.titleLarge),
          ...accountExpenses.entries.map(
            (e) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(e.key.color),
                child: Text(
                  e.key.icon,
                  style: const TextStyle(fontFamily: 'MaterialIcons'),
                ),
              ),
              title: Text(e.key.name),
              trailing: Text('$currency${e.value.toStringAsFixed(2)}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionsView(initialAccountId: e.key.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<CategoryEntity, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sections = data.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        radius: 40,
        color: Color(e.key.color),
        showTitle: false,
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}

class _IncomeTab extends StatelessWidget {
  final AnalyticsHelper helper;
  final String currency;
  const _IncomeTab({required this.helper, required this.currency});

  @override
  Widget build(BuildContext context) {
    final accountIncome = helper.accountIncome;

    if (accountIncome.isEmpty) {
      return const Center(child: Text('No income data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChart(context, accountIncome),
          const SizedBox(height: 24),
          Text('By Account', style: Theme.of(context).textTheme.titleLarge),
          ...accountIncome.entries.map(
            (e) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(e.key.color),
                child: Text(
                  e.key.icon,
                  style: const TextStyle(fontFamily: 'MaterialIcons'),
                ),
              ),
              title: Text(e.key.name),
              trailing: Text('$currency${e.value.toStringAsFixed(2)}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionsView(initialAccountId: e.key.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<Account, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sections = data.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        radius: 40,
        color: Color(e.key.color),
        showTitle: false,
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}
