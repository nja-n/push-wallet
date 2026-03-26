import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/account/domain/usecases/account_usecases.dart';
import 'package:push_wallet/core/usecases/usecase.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final GetAccounts getAccounts;
  final AddAccount addAccount;
  final DeleteAccount deleteAccount;
  final UpdateAccount updateAccount;
  final Box settingsBox;

  AccountCubit({
    required this.getAccounts,
    required this.addAccount,
    required this.deleteAccount,
    required this.updateAccount,
    required this.settingsBox,
  }) : super(AccountInitial());

  Future<void> loadAccounts() async {
    emit(AccountLoading());
    final result = await getAccounts(NoParams());
    result.fold(
      (failure) => emit(const AccountError('Failed to load accounts')),
      (accounts) {
        final order = settingsBox.get('account_order') as List<dynamic>?;
        if (order != null) {
          final idList = order.cast<String>();
          accounts.sort((a, b) {
            final indexA = idList.indexOf(a.id);
            final indexB = idList.indexOf(b.id);
            if (indexA == -1 && indexB == -1) return 0;
            if (indexA == -1) return 1;
            if (indexB == -1) return -1;
            return indexA.compareTo(indexB);
          });
        }
        emit(AccountLoaded(accounts));
      },
    );
  }

  Future<void> reorderAccount(int oldIndex, int newIndex) async {
    final currentState = state;
    if (currentState is AccountLoaded) {
      final accounts = List<Account>.from(currentState.accounts);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = accounts.removeAt(oldIndex);
      accounts.insert(newIndex, item);

      final order = accounts.map((a) => a.id).toList();
      await settingsBox.put('account_order', order);
      emit(AccountLoaded(accounts));
    }
  }

  Future<void> createAccount(Account account) async {
    emit(AccountLoading());
    final result = await addAccount(account);
    result.fold(
      (failure) => emit(const AccountError('Failed to add account')),
      (_) async {
        final order = settingsBox.get('account_order', defaultValue: <String>[]) as List<dynamic>;
        final idList = List<String>.from(order);
        if (!idList.contains(account.id)) {
          idList.add(account.id);
          await settingsBox.put('account_order', idList);
        }
        loadAccounts();
      },
    );
  }

  Future<void> removeAccount(String id) async {
    emit(AccountLoading());
    final result = await deleteAccount(id);
    result.fold(
      (failure) => emit(const AccountError('Failed to delete account')),
      (_) async {
        final order = settingsBox.get('account_order') as List<dynamic>?;
        if (order != null) {
          final idList = List<String>.from(order);
          idList.remove(id);
          await settingsBox.put('account_order', idList);
        }
        loadAccounts();
      },
    );
  }

  Future<void> editAccount(Account account) async {
    emit(AccountLoading());
    final result = await updateAccount(account);
    result.fold(
      (failure) => emit(const AccountError('Failed to update account')),
      (_) => loadAccounts(),
    );
  }
}
