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
}
