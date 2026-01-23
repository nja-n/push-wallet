import 'package:equatable/equatable.dart';

class SubCategory extends Equatable {
  final String id;
  final String name;

  const SubCategory({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
