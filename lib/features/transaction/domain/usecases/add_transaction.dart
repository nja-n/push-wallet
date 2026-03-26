import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../account/domain/entities/account.dart';
import '../../../account/domain/repositories/account_repository.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class AddTransaction implements UseCase<void, TransactionEntity> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;

  AddTransaction(this.transactionRepository, this.accountRepository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity transaction) async {
    // 1. Save Transaction
    final result = await transactionRepository.addTransaction(transaction);
    return result.fold((failure) => Left(failure), (_) async {
      // 2. Update Account Balances
      return await _updateBalances(transaction);
    });
  }

  Future<Either<Failure, void>> _updateBalances(
    TransactionEntity transaction,
  ) async {
    final accountsResult = await accountRepository.getAccounts();
    return accountsResult.fold((failure) => Left(failure), (accounts) async {
      final sourceAccountHelper = accounts.where(
        (a) => a.id == transaction.accountId,
      );
      if (sourceAccountHelper.isEmpty)
        return Left(CacheFailure()); // Account not found
      final sourceAccount = sourceAccountHelper.first;

      Account updatedSource;

      if (transaction.type == TransactionType.income) {
        // Income
        // If Card: Repayment (Decrease Debt/Balance)
        // If Asset: Increase Balance
        final newBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance - transaction.amount
            : sourceAccount.balance + transaction.amount;

        updatedSource = Account(
          id: sourceAccount.id,
          name: sourceAccount.name,
          type: sourceAccount.type,
          balance: newBalance,
          color: sourceAccount.color,
          icon: sourceAccount.icon,
          creditLimit: sourceAccount.creditLimit,
        );
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.expense) {
        // Expense
        // If Card: Purchase (Increase Debt/Balance)
        // If Asset: Decrease Balance
        final newBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance + transaction.amount
            : sourceAccount.balance - transaction.amount;

        updatedSource = Account(
          id: sourceAccount.id,
          name: sourceAccount.name,
          type: sourceAccount.type,
          balance: newBalance,
          color: sourceAccount.color,
          icon: sourceAccount.icon,
          creditLimit: sourceAccount.creditLimit,
        );
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.transfer) {
        // Transfer Check: Source
        // If Source is Card: Transferring OUT (Cash Advance?) -> Increase Debt
        // If Source is Asset: Decrease Balance
        final newSourceBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance + transaction.amount
            : sourceAccount.balance - transaction.amount;

        updatedSource = Account(
          id: sourceAccount.id,
          name: sourceAccount.name,
          type: sourceAccount.type,
          balance: newSourceBalance,
          color: sourceAccount.color,
          icon: sourceAccount.icon,
          creditLimit: sourceAccount.creditLimit,
        );
        await accountRepository.updateAccount(updatedSource);

        if (transaction.toAccountId != null) {
          final destAccountHelper = accounts.where(
            (a) => a.id == transaction.toAccountId,
          );
          if (destAccountHelper.isNotEmpty) {
            final destAccount = destAccountHelper.first;

            // Transfer Check: Destination
            // If Dest is Card: Payment/Repayment -> Decrease Debt
            // If Dest is Asset: Increase Balance
            final newDestBalance = (destAccount.type == 'Card' || destAccount.type == 'Loan')
                ? destAccount.balance - transaction.amount
                : destAccount.balance + transaction.amount;

            final updatedDest = Account(
              id: destAccount.id,
              name: destAccount.name,
              type: destAccount.type,
              balance: newDestBalance,
              color: destAccount.color,
              icon: destAccount.icon,
              creditLimit: destAccount.creditLimit,
            );
            await accountRepository.updateAccount(updatedDest);
          }
        }
      }
      return const Right(null);
    });
  }
}
