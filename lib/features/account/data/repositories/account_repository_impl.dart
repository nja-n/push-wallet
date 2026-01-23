import 'package:fpdart/fpdart.dart';

import 'package:push_wallet/core/error/failures.dart';
import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/account/domain/repositories/account_repository.dart';
import 'package:push_wallet/features/account/data/datasources/account_local_datasource.dart';
import 'package:push_wallet/features/account/data/models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountLocalDataSource localDataSource;

  AccountRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Account>>> getAccounts() async {
    try {
      final models = await localDataSource.getAccounts();
      final entities = models.map((e) => e.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addAccount(Account account) async {
    try {
      await localDataSource.cacheAccount(AccountModel.fromEntity(account));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String id) async {
    try {
      await localDataSource.deleteAccount(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateAccount(Account account) async {
    try {
      await localDataSource.updateAccount(AccountModel.fromEntity(account));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
