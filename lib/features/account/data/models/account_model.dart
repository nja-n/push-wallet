import 'package:hive/hive.dart';
import '../../domain/entities/account.dart';

part 'account_model.g.dart';

@HiveType(typeId: 0)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final double balance;

  @HiveField(4)
  final int color;

  @HiveField(5)
  final String icon;

  @HiveField(6)
  final double? creditLimit;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
    this.creditLimit,
  });

  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      id: account.id,
      name: account.name,
      type: account.type,
      balance: account.balance,
      color: account.color,
      icon: account.icon,
      creditLimit: account.creditLimit,
    );
  }

  Account toEntity() {
    return Account(
      id: id,
      name: name,
      type: type,
      balance: balance,
      color: color,
      icon: icon,
      creditLimit: creditLimit,
    );
  }
}
