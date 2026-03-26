import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/category_usecases.dart';
import '../../../../core/usecases/usecase.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategories getCategories;
  final AddCategory addCategory;
  final DeleteCategory deleteCategory;
  final UpdateCategory updateCategory;
  final Box settingsBox;

  CategoryCubit({
    required this.getCategories,
    required this.addCategory,
    required this.deleteCategory,
    required this.updateCategory,
    required this.settingsBox,
  }) : super(CategoryInitial());

  Future<void> loadCategories() async {
    emit(CategoryLoading());
    final result = await getCategories(NoParams());
    result.fold(
      (failure) => emit(const CategoryError('Failed to load categories')),
      (categories) {
        final activeCategories = categories.where((c) => !c.isDeleted).toList();
        
        // Apply sorting
        final incomeOrder = settingsBox.get('category_order_income') as List<dynamic>?;
        final expenseOrder = settingsBox.get('category_order_expense') as List<dynamic>?;

        final incomeList = activeCategories.where((c) => c.isIncome).toList();
        final expenseList = activeCategories.where((c) => !c.isIncome).toList();

        _sortByIdList(incomeList, incomeOrder?.cast<String>());
        _sortByIdList(expenseList, expenseOrder?.cast<String>());

        emit(CategoryLoaded([...incomeList, ...expenseList]));
      },
    );
  }

  void _sortByIdList(List<CategoryEntity> list, List<String>? idOrder) {
    if (idOrder == null) return;
    list.sort((a, b) {
      final indexA = idOrder.indexOf(a.id);
      final indexB = idOrder.indexOf(b.id);
      if (indexA == -1 && indexB == -1) return 0;
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });
  }

  Future<void> reorderCategory(int oldIndex, int newIndex, bool isIncome) async {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      final categories = currentState.categories.where((c) => c.isIncome == isIncome).toList();
      if (newIndex > oldIndex) newIndex -= 1;
      final item = categories.removeAt(oldIndex);
      categories.insert(newIndex, item);

      final order = categories.map((c) => c.id).toList();
      final key = isIncome ? 'category_order_income' : 'category_order_expense';
      await settingsBox.put(key, order);
      
      loadCategories(); // Refresh full state
    }
  }

  Future<void> createCategory(CategoryEntity category) async {
    emit(CategoryLoading());
    final result = await addCategory(category);
    result.fold(
      (failure) => emit(const CategoryError('Failed to add category')),
      (_) async {
        final key = category.isIncome ? 'category_order_income' : 'category_order_expense';
        final order = settingsBox.get(key, defaultValue: <String>[]) as List<dynamic>;
        final idList = List<String>.from(order);
        if (!idList.contains(category.id)) {
          idList.add(category.id);
          await settingsBox.put(key, idList);
        }
        loadCategories();
      },
    );
  }

  Future<void> editCategory(CategoryEntity category) async {
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

        final softDeletedCategory = CategoryEntity(
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
          (_) async {
            final key = categoryToDelete.isIncome ? 'category_order_income' : 'category_order_expense';
            final order = settingsBox.get(key) as List<dynamic>?;
            if (order != null) {
              final idList = List<String>.from(order);
              idList.remove(id);
              await settingsBox.put(key, idList);
            }
            loadCategories();
          },
        );
      } catch (e) {
        emit(const CategoryError('Category not found'));
      }
    }
  }
}
