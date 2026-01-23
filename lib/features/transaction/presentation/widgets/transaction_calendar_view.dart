import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:push_wallet/features/transaction/domain/entities/transaction_entity.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';

class TransactionCalendarView extends StatefulWidget {
  final List<TransactionEntity> transactions;

  const TransactionCalendarView({super.key, required this.transactions});

  @override
  State<TransactionCalendarView> createState() =>
      _TransactionCalendarViewState();
}

class _TransactionCalendarViewState extends State<TransactionCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _showTransactionsForDay(context, selectedDay);
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          return _buildDailySummary(date);
        },
      ),
    );
  }

  Widget? _buildDailySummary(DateTime date) {
    final dayTransactions = widget.transactions.where((t) {
      return isSameDay(t.date, date);
    }).toList();

    if (dayTransactions.isEmpty) return null;

    double income = 0;
    double expense = 0;
    bool hasTransfer = false;

    for (var t in dayTransactions) {
      if (t.type == TransactionType.income) income += t.amount;
      if (t.type == TransactionType.expense) expense += t.amount;
      if (t.type == TransactionType.transfer) hasTransfer = true;
    }

    return Positioned(
      bottom: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (income > 0)
            Text(
              '+${NumberFormat.compact().format(income)}',
              style: const TextStyle(color: Colors.green, fontSize: 10),
            ),
          if (expense > 0)
            Text(
              '-${NumberFormat.compact().format(expense)}',
              style: const TextStyle(color: Colors.red, fontSize: 10),
            ),
          if (hasTransfer)
            const Icon(Icons.swap_horiz, size: 10, color: Colors.blue),
        ],
      ),
    );
  }

  void _showTransactionsForDay(BuildContext context, DateTime date) {
    final dayTransactions = widget.transactions.where((t) {
      return isSameDay(t.date, date);
    }).toList();

    // Capture state from parent context to ensure data availability in dialog
    final categoryState = context.read<CategoryCubit>().state;
    final accountState = context.read<AccountCubit>().state;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(DateFormat.yMMMd().format(date)),
          content: SizedBox(
            width: double.maxFinite,
            child: dayTransactions.isEmpty
                ? const Text('No transactions for this day.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: dayTransactions.length,
                    itemBuilder: (context, index) {
                      final t = dayTransactions[index];
                      return _buildTransactionTile(
                        context,
                        t,
                        categoryState,
                        accountState,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionEntity t,
    CategoryState categoryState,
    AccountState accountState,
  ) {
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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: t.type == TransactionType.income
            ? Colors.green.withOpacity(0.2)
            : t.type == TransactionType.expense
            ? Colors.red.withOpacity(0.2)
            : Colors.blue.withOpacity(0.2),
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
      title: Text(t.description.isEmpty ? 'No Desc' : t.description),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$categoryName$subCategoryName • $accountName',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '$formattedTime • ${t.type.name}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Text(
        t.amount.toStringAsFixed(2),
        style: TextStyle(
          color: t.type == TransactionType.income
              ? Colors.green
              : t.type == TransactionType.expense
              ? Colors.red
              : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
