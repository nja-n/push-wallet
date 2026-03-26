import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../account/domain/entities/account.dart';
import '../../../account/domain/repositories/account_repository.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransaction implements UseCase<void, TransactionEntity> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;

  UpdateTransaction(this.transactionRepository, this.accountRepository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity transaction) async {
    // 1. Get Old Transaction
    final transactionsResult = await transactionRepository.getTransactions();
    return transactionsResult.fold((failure) => Left(failure), (
      transactions,
    ) async {
      final oldTransactionHelper = transactions.where(
        (t) => t.id == transaction.id,
      );
      if (oldTransactionHelper.isEmpty) {
        return Left(CacheFailure()); // Transaction not found
      }
      final oldTransaction = oldTransactionHelper.first;

      // 2. Revert Old Balances
      final revertResult = await _revertBalances(oldTransaction);
      return revertResult.fold((failure) => Left(failure), (_) async {
        // 3. Apply New Balances
        final applyResult = await _applyBalances(transaction);
        return applyResult.fold((failure) => Left(failure), (_) async {
          // 4. Update Transaction
          return await transactionRepository.updateTransaction(transaction);
        });
      });
    });
  }

  Future<Either<Failure, void>> _revertBalances(
    TransactionEntity transaction,
  ) async {
    // Logic from DeleteTransaction
    final accountsResult = await accountRepository.getAccounts();
    return accountsResult.fold((failure) => Left(failure), (accounts) async {
      final sourceAccountHelper = accounts.where(
        (a) => a.id == transaction.accountId,
      );
      if (sourceAccountHelper.isEmpty) return Left(CacheFailure());
      final sourceAccount = sourceAccountHelper.first;

      Account updatedSource;
      
      if (transaction.type == TransactionType.income) {
        final newBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance + transaction.amount
            : sourceAccount.balance - transaction.amount;
        updatedSource = sourceAccount.copyWith(balance: newBalance);
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.expense) {
        // Revert Expense: Card ? - amt : + amt
        final newBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance - transaction.amount
            : sourceAccount.balance + transaction.amount;
        updatedSource = sourceAccount.copyWith(balance: newBalance);
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.transfer) {
        // Revert Source: Card ? - amt : + amt
        final newSourceBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
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
            // Revert Dest: Card ? + amt : - amt
            final newDestBalance = (destAccount.type == 'Card' || destAccount.type == 'Loan')
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

  Future<Either<Failure, void>> _applyBalances(
    TransactionEntity transaction,
  ) async {
    // Logic from AddTransaction
    final accountsResult = await accountRepository.getAccounts();
    return accountsResult.fold((failure) => Left(failure), (accounts) async {
      final sourceAccountHelper = accounts.where(
        (a) => a.id == transaction.accountId,
      );
      if (sourceAccountHelper.isEmpty) return Left(CacheFailure());
      final sourceAccount = sourceAccountHelper.first;

      Account updatedSource;

      if (transaction.type == TransactionType.income) {
        // Apply Income: Card ? - amt : + amt
        final newBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance - transaction.amount
            : sourceAccount.balance + transaction.amount;
        updatedSource = sourceAccount.copyWith(balance: newBalance);
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.expense) {
        // Apply Expense: Card ? + amt : - amt
        final newBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance + transaction.amount
            : sourceAccount.balance - transaction.amount;
        updatedSource = sourceAccount.copyWith(balance: newBalance);
        await accountRepository.updateAccount(updatedSource);
      } else if (transaction.type == TransactionType.transfer) {
        // Apply Source: Card ? + amt : - amt
        final newSourceBalance = (sourceAccount.type == 'Card' || sourceAccount.type == 'Loan')
            ? sourceAccount.balance + transaction.amount
            : sourceAccount.balance - transaction.amount;
        updatedSource = sourceAccount.copyWith(balance: newSourceBalance);
        await accountRepository.updateAccount(updatedSource);

        if (transaction.toAccountId != null) {
          final destAccountHelper = accounts.where(
            (a) => a.id == transaction.toAccountId,
          );
          if (destAccountHelper.isNotEmpty) {
            final destAccount = destAccountHelper.first;
            // Apply Dest: Card ? - amt : + amt
            final newDestBalance = (destAccount.type == 'Card' || destAccount.type == 'Loan')
                ? destAccount.balance - transaction.amount
                : destAccount.balance + transaction.amount;
            final updatedDest = destAccount.copyWith(balance: newDestBalance);
            await accountRepository.updateAccount(updatedDest);
          }
        }
      }
      return const Right(null);
    });
  }
}
