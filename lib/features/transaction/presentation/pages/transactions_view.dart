import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/transaction_calendar_view.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/transaction_list_view.dart';

// Note: imports like account_cubit etc might be used in sheet but not here anymore locally, but might be needed if I kept any logic.
// Actually ListView is here.

import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';

class TransactionsView extends StatefulWidget {
  final String? initialAccountId;
  final String? initialCategoryId;

  const TransactionsView({
    super.key,
    this.initialAccountId,
    this.initialCategoryId,
  });

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  bool _isCalendarView = false;
  final Set<String> _selectedAccountIds = {};
  final Set<String> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialAccountId != null) {
      _selectedAccountIds.add(widget.initialAccountId!);
    }
    if (widget.initialCategoryId != null) {
      _selectedCategoryIds.add(widget.initialCategoryId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
            tooltip: _isCalendarView ? 'Switch to List' : 'Switch to Calendar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => const AddTransactionSheet(),
        ),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionLoaded) {
            var transactions = state.transactions;

            // Apply Filters
            if (_selectedAccountIds.isNotEmpty) {
              transactions = transactions
                  .where((t) => _selectedAccountIds.contains(t.accountId))
                  .toList();
            }
            if (_selectedCategoryIds.isNotEmpty) {
              transactions = transactions
                  .where((t) => _selectedCategoryIds.contains(t.categoryId))
                  .toList();
            }

            if (transactions.isEmpty) {
              return const Center(child: Text('No transactions found.'));
            }
            return _isCalendarView
                ? TransactionCalendarView(transactions: transactions)
                : TransactionListView(transactions: transactions);
          }
          if (state is TransactionError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Transactions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedAccountIds.clear();
                                _selectedCategoryIds.clear();
                              });
                              // Also update parent state to clear filters immediately
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Accounts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<AccountCubit, AccountState>(
                        builder: (context, state) {
                          if (state is AccountLoaded) {
                            return Wrap(
                              spacing: 8,
                              children: state.accounts.map((a) {
                                final isSelected = _selectedAccountIds.contains(
                                  a.id,
                                );
                                return FilterChip(
                                  label: Text(a.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedAccountIds.add(a.id);
                                      } else {
                                        _selectedAccountIds.remove(a.id);
                                      }
                                    });
                                    // Update parent state to reflect filter changes immediately on list behind sheet?
                                    // Or only when sheet closes? user said "instant view update of popup not working".
                                    // If we want main list to update too, we call setState.
                                    setState(() {});
                                  },
                                );
                              }).toList(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<CategoryCubit, CategoryState>(
                        builder: (context, state) {
                          if (state is CategoryLoaded) {
                            return Wrap(
                              spacing: 8,
                              children: state.categories.map((c) {
                                final isSelected = _selectedCategoryIds
                                    .contains(c.id);
                                return FilterChip(
                                  label: Text(c.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedCategoryIds.add(c.id);
                                      } else {
                                        _selectedCategoryIds.remove(c.id);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              }).toList(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
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
}
