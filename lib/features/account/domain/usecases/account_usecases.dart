import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class GetAccounts implements UseCase<List<Account>, NoParams> {
  final AccountRepository repository;

  GetAccounts(this.repository);

  @override
  Future<Either<Failure, List<Account>>> call(NoParams params) {
    return repository.getAccounts();
  }
}

class AddAccount implements UseCase<void, Account> {
  final AccountRepository repository;

  AddAccount(this.repository);

  @override
  Future<Either<Failure, void>> call(Account account) {
    return repository.addAccount(account);
  }
}

class DeleteAccount implements UseCase<void, String> {
  final AccountRepository repository;

  DeleteAccount(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteAccount(id);
  }
}

class UpdateAccount implements UseCase<void, Account> {
  final AccountRepository repository;

  UpdateAccount(this.repository);

  @override
  Future<Either<Failure, void>> call(Account account) {
    return repository.updateAccount(account);
  }
}
