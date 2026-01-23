import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart'; // absolute

import 'package:push_wallet/features/category/domain/entities/category.dart';
import 'package:push_wallet/features/category/presentation/widgets/save_category_sheet.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Income'),
              Tab(text: 'Expense'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCategoryDialog(context),
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoryLoaded) {
              final incomeCategories = state.categories
                  .where((c) => c.isIncome)
                  .toList();
              final expenseCategories = state.categories
                  .where((c) => !c.isIncome)
                  .toList();

              return TabBarView(
                children: [
                  _buildCategoryList(context, incomeCategories),
                  _buildCategoryList(context, expenseCategories),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(cat.color),
            child: Text(cat.icon, style: const TextStyle(fontSize: 24)),
          ),
          title: Text(cat.name),
          subtitle: Text(
            '${cat.subCategories.length} subcategories',
          ), // Optional: show sub count
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () =>
                context.read<CategoryCubit>().removeCategory(cat.id),
          ),
          onTap: () => _showAddCategoryDialog(context, category: cat),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, {Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveCategorySheet(category: category),
    );
  }
}
