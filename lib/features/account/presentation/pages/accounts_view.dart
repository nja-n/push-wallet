import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/account/presentation/widgets/save_account_sheet.dart';
import 'package:push_wallet/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  final GlobalKey _addAccountKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
  }

  void _showTutorial() async {
    final box = await Hive.openBox('settings');
    bool shown = box.get('tutorial_accounts', defaultValue: false);
    if (!shown && mounted) {
      ShowCaseWidget.of(context).startShowCase([_addAccountKey]);
      box.put('tutorial_accounts', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: Showcase(
        key: _addAccountKey,
        title: 'Create Account',
        description: 'Add your bank accounts, cards, or wallets here.',
        child: FloatingActionButton(
          onPressed: () => _showAddAccountDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final currency =
              (settingsState is SettingsLoaded)
                  ? settingsState.currencySymbol
                  : '\$';

          return BlocBuilder<AccountCubit, AccountState>(
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
                      color: Theme.of(context).primaryColor.withValues(
                        alpha: 0.1,
                      ),
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
                            '$currency${totalBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  totalBalance >= 0 ? Colors.green : Colors.red,
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
                                ' • Limit: $currency${account.creditLimit!.toStringAsFixed(0)} • Avail: $currency${available.toStringAsFixed(2)}';
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
                                '$currency${account.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isCard ? Colors.red : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap:
                                  () => _showAddAccountDialog(
                                    context,
                                    account: account,
                                  ),
                              onLongPress:
                                  () => context
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
          );
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
