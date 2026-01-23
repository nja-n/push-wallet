import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';

import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/account/presentation/widgets/save_account_sheet.dart';

class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          if (state is AccountLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AccountLoaded) {
            if (state.accounts.isEmpty) {
              return const Center(child: Text('No accounts. Add one!'));
            }

            double totalBalance = 0;
            for (var acc in state.accounts) {
              if (acc.type == 'Card') {
                totalBalance -= acc.balance; // Debt subtracts from total
              } else {
                totalBalance += acc.balance;
              }
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${totalBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: totalBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.accounts.length,
                    itemBuilder: (context, index) {
                      final account = state.accounts[index];
                      final isCard = account.type == 'Card';

                      String subtitle = account.type;
                      if (isCard && account.creditLimit != null) {
                        final available =
                            account.creditLimit! - account.balance;
                        subtitle +=
                            ' • Limit: \$${account.creditLimit!.toStringAsFixed(0)} • Avail: \$${available.toStringAsFixed(2)}';
                      }

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(account.color),
                            child: Text(
                              account.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Text(account.name),
                          subtitle: Text(subtitle),
                          trailing: Text(
                            '\$${account.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isCard ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () =>
                              _showAddAccountDialog(context, account: account),
                          onLongPress: () => context
                              .read<AccountCubit>()
                              .removeAccount(account.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveAccountSheet(account: account),
    );
  }
}
