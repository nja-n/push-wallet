import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, void>> addCategory(CategoryEntity category);
  Future<Either<Failure, void>> deleteCategory(String id);
  Future<Either<Failure, void>> updateCategory(CategoryEntity category);
}

class GetCategories implements UseCase<List<CategoryEntity>, NoParams> {
  final CategoryRepository repository;
  GetCategories(this.repository);
  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) =>
      repository.getCategories();
}

class AddCategory implements UseCase<void, CategoryEntity> {
  final CategoryRepository repository;
  AddCategory(this.repository);
  @override
  Future<Either<Failure, void>> call(CategoryEntity category) =>
      repository.addCategory(category);
}

class UpdateCategory implements UseCase<void, CategoryEntity> {
  final CategoryRepository repository;
  UpdateCategory(this.repository);
  @override
  Future<Either<Failure, void>> call(CategoryEntity category) =>
      repository.updateCategory(category);
}

class DeleteCategory implements UseCase<void, String> {
  final CategoryRepository repository;
  DeleteCategory(this.repository);
  @override
  Future<Either<Failure, void>> call(String id) =>
      repository.deleteCategory(id);
}
