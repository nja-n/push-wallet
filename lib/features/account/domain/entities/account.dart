import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final String id;
  final String name;
  final String type; // e.g., 'Cash', 'Bank', 'Wallet'
  final double balance;
  final int color;
  final String icon;
  final double? creditLimit;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
    this.creditLimit,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    color,
    icon,
    creditLimit,
  ];
  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    int? color,
    String? icon,
    double? creditLimit,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      creditLimit: creditLimit ?? this.creditLimit,
    );
  }
}
