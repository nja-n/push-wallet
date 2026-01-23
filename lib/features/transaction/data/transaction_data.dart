import 'package:hive/hive.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../domain/entities/transaction_entity.dart';
import '../domain/repositories/transaction_repository.dart';

part 'transaction_data.g.dart';

@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String? categoryId;
  @HiveField(5)
  final String accountId;
  @HiveField(6)
  final String? toAccountId;
  @HiveField(7)
  final int typeIndex; // Store enum as int
  @HiveField(8)
  final String? subCategoryId;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.typeIndex,
    this.subCategoryId,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      date: entity.date,
      description: entity.description,
      categoryId: entity.categoryId,
      accountId: entity.accountId,
      toAccountId: entity.toAccountId,
      typeIndex: entity.type.index,
      subCategoryId: entity.subCategoryId,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      amount: amount,
      date: date,
      description: description,
      categoryId: categoryId,
      accountId: accountId,
      toAccountId: toAccountId,
      subCategoryId: subCategoryId,
      type: TransactionType.values[typeIndex],
    );
  }
}

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransaction(TransactionModel transaction);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final Box<TransactionModel> box;
  TransactionLocalDataSourceImpl(this.box);

  @override
  Future<List<TransactionModel>> getTransactions() async {
    // Sort by date descending
    final list = box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await box.put(transaction.id, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await box.delete(id);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await box.put(transaction.id, transaction);
  }
}

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource dataSource;
  TransactionRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions() async {
    try {
      final models = await dataSource.getTransactions();
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      await dataSource.addTransaction(TransactionModel.fromEntity(transaction));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await dataSource.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      await dataSource.updateTransaction(
        TransactionModel.fromEntity(transaction),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
