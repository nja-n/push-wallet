import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/category_usecases.dart';
import '../../../../core/usecases/usecase.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategories getCategories;
  final AddCategory addCategory;
  final DeleteCategory deleteCategory;
  final UpdateCategory updateCategory;

  CategoryCubit({
    required this.getCategories,
    required this.addCategory,
    required this.deleteCategory,
    required this.updateCategory,
  }) : super(CategoryInitial());

  Future<void> loadCategories() async {
    emit(CategoryLoading());
    final result = await getCategories(NoParams());
    result.fold(
      (failure) => emit(const CategoryError('Failed to load categories')),
      (categories) =>
          emit(CategoryLoaded(categories.where((c) => !c.isDeleted).toList())),
    );
  }

  Future<void> createCategory(Category category) async {
    emit(CategoryLoading());
    final result = await addCategory(category);
    result.fold(
      (failure) => emit(const CategoryError('Failed to add category')),
      (_) => loadCategories(),
    );
  }

  Future<void> editCategory(Category category) async {
    emit(CategoryLoading());
    final result = await updateCategory(category);
    result.fold(
      (failure) => emit(const CategoryError('Failed to update category')),
      (_) => loadCategories(),
    );
  }

  Future<void> removeCategory(String id) async {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      try {
        final categoryToDelete = currentState.categories.firstWhere(
          (c) => c.id == id,
        );
        emit(CategoryLoading());

        final softDeletedCategory = Category(
          id: categoryToDelete.id,
          name: categoryToDelete.name,
          isIncome: categoryToDelete.isIncome,
          icon: categoryToDelete.icon,
          color: categoryToDelete.color,
          subCategories: categoryToDelete.subCategories,
          isDeleted: true,
        );

        final result = await updateCategory(softDeletedCategory);
        result.fold(
          (failure) => emit(const CategoryError('Failed to delete category')),
          (_) => loadCategories(),
        );
      } catch (e) {
        emit(const CategoryError('Category not found'));
      }
    }
  }
}
