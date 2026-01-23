import 'package:equatable/equatable.dart';
import 'sub_category.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final bool isIncome;
  final String icon; // Emoji character
  final int color;
  final List<SubCategory> subCategories;
  final bool isDeleted;

  const Category({
    required this.id,
    required this.name,
    required this.isIncome,
    required this.icon,
    required this.color,
    this.subCategories = const [],
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    isIncome,
    icon,
    color,
    subCategories,
    isDeleted,
  ];
}
