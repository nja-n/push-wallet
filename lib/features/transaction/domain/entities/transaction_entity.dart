import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer }

class TransactionEntity extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String? categoryId;
  final String? subCategoryId;
  final String accountId;
  final String? toAccountId; // For transfer
  final TransactionType type;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    this.categoryId,
    this.subCategoryId,
    required this.accountId,
    this.toAccountId,
    required this.type,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    date,
    description,
    categoryId,
    subCategoryId,
    accountId,
    toAccountId,
    type,
  ];
}
