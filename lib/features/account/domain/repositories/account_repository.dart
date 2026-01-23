import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/account.dart';

abstract class AccountRepository {
  Future<Either<Failure, List<Account>>> getAccounts();
  Future<Either<Failure, void>> addAccount(Account account);
  Future<Either<Failure, void>> deleteAccount(String id);
  Future<Either<Failure, void>> updateAccount(Account account);
}
