import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../account/domain/entities/account.dart';
import '../../../account/domain/repositories/account_repository.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransaction implements UseCase<void, TransactionEntity> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;

  DeleteTransaction(this.transactionRepository, this.accountRepository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity transaction) async {
    // 1. Revert Account Balances
    final result = await _revertBalances(transaction);
    return result.fold((failure) => Left(failure), (_) async {
      // 2. Delete Transaction
      return await transactionRepository.deleteTransaction(transaction.id);
    });
  }

  Future<Either<Failure, void>> _revertBalances(
    TransactionEntity transaction,
  ) async {
    final accountsResult = await accountRepository.getAccounts();
    return accountsResult.fold((failure) => Left(failure), (accounts) async {
      final sourceAccountHelper = accounts.where(
        (a) => a.id == transaction.accountId,
      );
      if (sourceAccountHelper.isEmpty) return Left(CacheFailure());
      final sourceAccount = sourceAccountHelper.first;

      Account updatedSource;

      // Logic is INVERTED from AddTransaction
      if (transaction.type == TransactionType.income) {
        // Income was: Card ? - amt : + amt
        // Revert: Card ? + amt : - amt
        final newBalance = sourceAccount.type == 'Card'
            ? sourceAccount.balance + transaction.amount
            : sourceAccount.balance - transaction.amount;

        updatedSource = sourceAccount.copyWith(balance: newBalance);
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.expense) {
        // Expense was: Card ? + amt : - amt
        // Revert: Card ? - amt : + amt
        final newBalance = sourceAccount.type == 'Card'
            ? sourceAccount.balance - transaction.amount
            : sourceAccount.balance + transaction.amount;

        updatedSource = sourceAccount.copyWith(balance: newBalance);
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.transfer) {
        // Transfer Source was: Card ? + amt : - amt
        // Revert Source: Card ? - amt : + amt
        final newSourceBalance = sourceAccount.type == 'Card'
            ? sourceAccount.balance - transaction.amount
            : sourceAccount.balance + transaction.amount;

        updatedSource = sourceAccount.copyWith(balance: newSourceBalance);
        await accountRepository.updateAccount(updatedSource);

        if (transaction.toAccountId != null) {
          final destAccountHelper = accounts.where(
            (a) => a.id == transaction.toAccountId,
          );
          if (destAccountHelper.isNotEmpty) {
            final destAccount = destAccountHelper.first;

            // Transfer Dest was: Card ? - amt : + amt
            // Revert Dest: Card ? + amt : - amt
            final newDestBalance = destAccount.type == 'Card'
                ? destAccount.balance + transaction.amount
                : destAccount.balance - transaction.amount;

            final updatedDest = destAccount.copyWith(balance: newDestBalance);
            await accountRepository.updateAccount(updatedDest);
          }
        }
      }
      return const Right(null);
    });
  }
}
