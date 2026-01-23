import 'package:hive/hive.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../domain/entities/category.dart';
import '../domain/entities/sub_category.dart';
import '../domain/usecases/category_usecases.dart'; // interface defined there or separate file, logic is here for data

part 'category_data.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final bool isIncome;
  @HiveField(3)
  final String icon;
  @HiveField(4)
  final int color;
  @HiveField(5)
  final List<SubCategoryModel> subCategories;
  @HiveField(6, defaultValue: false)
  final bool isDeleted;

  CategoryModel({
    required this.id,
    required this.name,
    required this.isIncome,
    required this.icon,
    required this.color,
    this.subCategories = const [],
    this.isDeleted = false,
  });

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      isIncome: category.isIncome,
      icon: category.icon,
      color: category.color,
      subCategories: category.subCategories
          .map((e) => SubCategoryModel.fromEntity(e))
          .toList(),
      isDeleted: category.isDeleted,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      isIncome: isIncome,
      icon: icon,
      color: color,
      subCategories: subCategories.map((e) => e.toEntity()).toList(),
      isDeleted: isDeleted,
    );
  }
}

@HiveType(typeId: 3)
class SubCategoryModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;

  SubCategoryModel({required this.id, required this.name});

  factory SubCategoryModel.fromEntity(SubCategory entity) {
    return SubCategoryModel(id: entity.id, name: entity.name);
  }

  SubCategory toEntity() => SubCategory(id: id, name: name);
}

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> cacheCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Future<void> updateCategory(CategoryModel category);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final Box<CategoryModel> categoryBox;
  CategoryLocalDataSourceImpl(this.categoryBox);

  @override
  Future<List<CategoryModel>> getCategories() async =>
      categoryBox.values.toList();

  @override
  Future<void> cacheCategory(CategoryModel category) async =>
      await categoryBox.put(category.id, category);

  @override
  Future<void> updateCategory(CategoryModel category) async =>
      await categoryBox.put(category.id, category);

  @override
  Future<void> deleteCategory(String id) async => await categoryBox.delete(id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;
  CategoryRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final models = await localDataSource.getCategories();
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addCategory(Category category) async {
    try {
      await localDataSource.cacheCategory(CategoryModel.fromEntity(category));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(Category category) async {
    try {
      await localDataSource.updateCategory(CategoryModel.fromEntity(category));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await localDataSource.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
