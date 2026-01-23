import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, void>> addCategory(Category category);
  Future<Either<Failure, void>> deleteCategory(String id);
  Future<Either<Failure, void>> updateCategory(Category category);
}

class GetCategories implements UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;
  GetCategories(this.repository);
  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) =>
      repository.getCategories();
}

class AddCategory implements UseCase<void, Category> {
  final CategoryRepository repository;
  AddCategory(this.repository);
  @override
  Future<Either<Failure, void>> call(Category category) =>
      repository.addCategory(category);
}

class UpdateCategory implements UseCase<void, Category> {
  final CategoryRepository repository;
  UpdateCategory(this.repository);
  @override
  Future<Either<Failure, void>> call(Category category) =>
      repository.updateCategory(category);
}

class DeleteCategory implements UseCase<void, String> {
  final CategoryRepository repository;
  DeleteCategory(this.repository);
  @override
  Future<Either<Failure, void>> call(String id) =>
      repository.deleteCategory(id);
}
