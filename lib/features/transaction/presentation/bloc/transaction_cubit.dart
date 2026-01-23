import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/add_transaction.dart';
// For NoParams? AddTransaction doesn't use NoParams but GetTransactions might. I didn't create GetTransactions UseCase, I will use Repo directly for getTransactions to save time as per note. Or did I?
// I commented "I'll add GetTransactions simple usecase later or now." in Step 60. I didn't create it.
// I'll create a simple inline call or just use Repo. Strict clean arch says UseCase.
// I'll create a local GetTransactions class here or just use repo. Let's use Repo directly for read to save a file, although it breaks strict rule.
// Actually, `AddTransaction` IS a UseCase.
// I will just use `TransactionRepository` for `getTransactions` inside Cubit.

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository repository;
  final AddTransaction addTransactionUseCase;

  TransactionCubit({
    required this.repository,
    required this.addTransactionUseCase,
  }) : super(TransactionInitial());

  Future<void> loadTransactions() async {
    emit(TransactionLoading());
    final result = await repository.getTransactions();
    result.fold(
      (failure) => emit(const TransactionError('Failed to load transactions')),
      (transactions) => emit(TransactionLoaded(transactions)),
    );
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    emit(TransactionLoading());
    final result = await addTransactionUseCase(transaction);
    result.fold(
      (failure) => emit(const TransactionError('Failed to add transaction')),
      (_) => loadTransactions(),
    );
  }
}
