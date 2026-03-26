import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';
import 'package:push_wallet/features/transaction/domain/entities/transaction_entity.dart';
import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'add_transaction_sheet.dart';
import 'package:push_wallet/features/settings/presentation/bloc/settings_cubit.dart';

class TransactionListView extends StatelessWidget {
  final List<TransactionEntity> transactions;

  const TransactionListView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group transactions by date
    final groupedTransactions = groupBy(
      transactions,
      (TransactionEntity t) => DateTime(t.date.year, t.date.month, t.date.day),
    );

    // Sort dates descending
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final currency =
            (settingsState is SettingsLoaded)
                ? settingsState.currencySymbol
                : '\$';

        return ListView.builder(
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayTransactions = groupedTransactions[date]!;

            // Calculate daily total
            double dailyIncome = 0;
            double dailyExpense = 0;

            for (var t in dayTransactions) {
              if (t.type == TransactionType.income) {
                dailyIncome += t.amount;
              } else if (t.type == TransactionType.expense) {
                dailyExpense += t.amount;
              }
            }

            final netAmount = dailyIncome - dailyExpense;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ExpansionTile(
                initiallyExpanded: index == 0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      netAmount >= 0
                          ? '+$currency${netAmount.toStringAsFixed(2)}'
                          : '-$currency${netAmount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: netAmount >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Inc: $currency${dailyIncome.toStringAsFixed(2)}  Exp: $currency${dailyExpense.toStringAsFixed(2)}',
                ),
                children:
                    dayTransactions.map((t) {
                      return _buildTransactionTile(context, t, currency);
                    }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionEntity t,
    String currency,
  ) {
    // Lookup details
    final categoryState = context.read<CategoryCubit>().state;
    final accountState = context.read<AccountCubit>().state;

    String categoryName = 'Uncategorized';
    String subCategoryName = '';
    String accountName = 'Unknown Account';

    if (categoryState is CategoryLoaded) {
      final category = categoryState.categories.firstWhereOrNull(
        (c) => c.id == t.categoryId,
      );
      if (category != null) {
        categoryName = category.name;
        if (t.subCategoryId != null) {
          final sub = category.subCategories.firstWhereOrNull(
            (s) => s.id == t.subCategoryId,
          );
          if (sub != null) {
            subCategoryName = ' (${sub.name})';
          }
        }
      }
    }

    if (accountState is AccountLoaded) {
      final account = accountState.accounts.firstWhereOrNull(
        (a) => a.id == t.accountId,
      );
      if (account != null) {
        accountName = account.name;
      }
    }

    final formattedTime = DateFormat.jm().format(t.date);

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: const Text(
                "Are you sure you want to delete this transaction?",
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "DELETE",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<TransactionCubit>().deleteTransaction(t);
        context.read<AccountCubit>().loadAccounts();
      },
      child: ListTile(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => AddTransactionSheet(transaction: t),
          );
        },
        leading: CircleAvatar(
          backgroundColor: t.type == TransactionType.income
              ? Colors.green.withValues(alpha: 0.1)
              : t.type == TransactionType.expense
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.2),
          child: Icon(
            t.type == TransactionType.income
                ? Icons.arrow_downward
                : t.type == TransactionType.expense
                ? Icons.arrow_upward
                : Icons.compare_arrows,
            color: t.type == TransactionType.income
                ? Colors.green
                : t.type == TransactionType.expense
                ? Colors.red
                : Colors.blue,
          ),
        ),
        title: Text(
          t.description.isEmpty ? 'No Description' : t.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$categoryName$subCategoryName • $accountName',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '$formattedTime • ${t.type.name.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          '$currency${t.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color:
                t.type == TransactionType.income
                    ? Colors.green
                    : t.type == TransactionType.expense
                    ? Colors.red
                    : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
