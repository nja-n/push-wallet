import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/account/domain/usecases/account_usecases.dart';
import 'package:push_wallet/core/usecases/usecase.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final GetAccounts getAccounts;
  final AddAccount addAccount;
  final DeleteAccount deleteAccount;
  final UpdateAccount updateAccount;

  AccountCubit({
    required this.getAccounts,
    required this.addAccount,
    required this.deleteAccount,
    required this.updateAccount,
  }) : super(AccountInitial());

  Future<void> loadAccounts() async {
    emit(AccountLoading());
    final result = await getAccounts(NoParams());
    result.fold(
      (failure) => emit(const AccountError('Failed to load accounts')),
      (accounts) => emit(AccountLoaded(accounts)),
    );
  }

  Future<void> createAccount(Account account) async {
    emit(AccountLoading());
    final result = await addAccount(account);
    result.fold(
      (failure) => emit(const AccountError('Failed to add account')),
      (_) => loadAccounts(),
    );
  }

  Future<void> removeAccount(String id) async {
    emit(AccountLoading());
    final result = await deleteAccount(id);
    result.fold(
      (failure) => emit(const AccountError('Failed to delete account')),
      (_) => loadAccounts(),
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
