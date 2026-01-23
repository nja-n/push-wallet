import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/transaction_calendar_view.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/transaction_list_view.dart';

// Note: imports like account_cubit etc might be used in sheet but not here anymore locally, but might be needed if I kept any logic.
// Actually ListView is here.

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  bool _isCalendarView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
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
            if (state.transactions.isEmpty) {
              return const Center(child: Text('No transactions yet.'));
            }
            return _isCalendarView
                ? TransactionCalendarView(transactions: state.transactions)
                : TransactionListView(transactions: state.transactions);
          }
          if (state is TransactionError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
