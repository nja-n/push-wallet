import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';
import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';
import 'package:push_wallet/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:push_wallet/features/settings/presentation/pages/settings_page.dart';
import 'package:push_wallet/core/services/analytics_helper.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:push_wallet/features/transaction/presentation/pages/transactions_view.dart';
import 'package:push_wallet/features/account/presentation/pages/accounts_view.dart';
import 'package:push_wallet/features/analytics/presentation/pages/analytics_view.dart';

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
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final currency =
              (settingsState is SettingsLoaded)
                  ? settingsState.currencySymbol
                  : '\$';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Summary Section
                _buildSummarySection(context, currency),
                const SizedBox(height: 24),

                // Accounts Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AccountsView(),
                                ),
                              ),
                          child: Text(
                            'Accounts',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildAccountsList(context, currency),
                const SizedBox(height: 24),

                // Analytics Section (Pie Chart)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsView(),
                          ),
                        ),
                    child: Text(
                      'Analytics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                _buildAnalyticsChart(context),
                const SizedBox(height: 24),

                // Recent Transactions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const Scaffold(
                                      body: TransactionsView(),
                                    ),
                              ),
                            ),
                        child: Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to Transactions Tab manually or just pop?
                          // Actually, Dashboard is part of Home. We can switch tab or push view.
                          // For simplicity, let's just use the bottom nav bar, but user asked for "View All" button route.
                          // Pushing TransactionsView directly might duplicate UI if it's already in tabs.
                          // Ideally we switch tab index. But here we can push a dedicated history page or just switch tab.
                          // Let's Find Ancestor NavigationBar? Or just tell user to click tab?
                          // User requested "view all button route to transation page".
                          // Let's try to switch tab if possible, or push a view.
                          // Since TransactionsView is a tab, pushing it might be weird.
                          // Let's Switch Tab!
                          // But providing access to the state of HomePage index is hard from here without Provider.
                          // Let's just push TransactionsView as a new screen for now.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => const Scaffold(
                                    body: TransactionsView(),
                                  ),
                            ), // Temporary wrapper
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                _buildRecentTransactions(context, currency),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, String currency) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, txState) {
        return BlocBuilder<AccountCubit, AccountState>(
          builder: (context, accState) {
            return BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, catState) {
                // Calculate Totals
                double totalBalance = 0;
                if (accState is AccountLoaded) {
                  totalBalance = accState.accounts.fold(
                    0,
                    (sum, item) =>
                        (item.type == 'Card' || item.type == 'Loan')
                            ? sum - item.balance
                            : sum + item.balance,
                  );
                }

                double income = 0;
                double expense = 0;

                if (txState is TransactionLoaded) {
                  final helper = AnalyticsHelper(
                    transactions: txState.transactions,
                    accounts: (accState is AccountLoaded)
                        ? accState.accounts
                        : [],
                    categories: (catState is CategoryLoaded)
                        ? catState.categories
                        : [],
                  );
                  income = helper.totalIncome;
                  expense = helper.totalExpense;
                }

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade800, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (totalBalance < 0)
                            const Icon(Icons.remove, color: Colors.white, size: 24),
                          Text(
                            '$currency${totalBalance.abs().toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.greenAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Income',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$currency${income.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expense',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$currency${expense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAccountsList(BuildContext context, String currency) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        if (state is AccountLoaded) {
          return SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.accounts.length,
              itemBuilder: (context, index) {
                final account = state.accounts[index];
                final isDebt = account.type == 'Card' || account.type == 'Loan';
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddTransactionSheet(initialAccountId: account.id),
                    );
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (isDebt)
                              const Icon(
                                Icons.remove,
                                color: Colors.red,
                                size: 14,
                              ),
                            Text(
                              '$currency${account.balance.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDebt ? Colors.red : Colors.green,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAnalyticsChart(BuildContext context) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, txState) {
        return BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, catState) {
            if (txState is TransactionLoaded && catState is CategoryLoaded) {
              final helper = AnalyticsHelper(
                transactions: txState.transactions,
                accounts: [],
                categories: catState.categories,
              );
              final data = helper.categoryExpenses;

              if (data.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No expense data to analyze')),
                );
              }

              return SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: data.entries.map((e) {
                      return PieChartSectionData(
                        value: e.value,
                        title: '',
                        radius: 50,
                        color: Color(e.key.color),
                        badgeWidget: _Badge(
                          e.key.icon,
                          size: 40,
                          borderColor: Color(e.key.color),
                        ),
                        badgePositionPercentageOffset: .98,
                      );
                    }).toList(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildRecentTransactions(BuildContext context, String currency) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoaded) {
          final recent = state.transactions.take(5).toList();
          if (recent.isEmpty)
            return const Center(child: Text('No transactions'));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final t = recent[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      t.type.index == 0
                          ? Colors.green.withOpacity(0.1)
                          : (t.type.index == 1
                              ? Colors.red.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1)),
                  child: Icon(
                    t.type.index == 0
                        ? Icons.arrow_downward
                        : (t.type.index == 1
                            ? Icons.arrow_upward
                            : Icons.swap_horiz),
                    color:
                        t.type.index == 0
                            ? Colors.green
                            : (t.type.index == 1 ? Colors.red : Colors.blue),
                  ),
                ),
                title: Text(
                  t.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  t.date.toString().substring(0, 10),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Text(
                  '$currency${t.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        t.type.index == 0
                            ? Colors.green
                            : (t.type.index == 1 ? Colors.red : Colors.blue),
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.size, required this.borderColor});
  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: FittedBox(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'MaterialIcons',
            ),
          ),
        ),
      ),
    );
  }
}
