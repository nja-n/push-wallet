import 'package:equatable/equatable.dart';

class SubCategoryEntity extends Equatable {
  final String id;
  final String name;

  const SubCategoryEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
