import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';
import 'package:push_wallet/features/category/domain/entities/category_entity.dart';
import 'package:push_wallet/features/category/presentation/widgets/save_category_sheet.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final GlobalKey _addCategoryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
  }

  void _showTutorial() async {
    final box = await Hive.openBox('settings');
    bool shown = box.get('tutorial_categories', defaultValue: false);
    if (!shown && mounted) {
      ShowCaseWidget.of(context).startShowCase([_addCategoryKey]);
      box.put('tutorial_categories', true);
    }
  }

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
        floatingActionButton: Showcase(
          key: _addCategoryKey,
          title: 'Create Category',
          description: 'Organize your finances by adding custom categories.',
          child: FloatingActionButton(
            onPressed: () => _showAddCategoryDialog(context),
            child: const Icon(Icons.add),
          ),
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

  Widget _buildCategoryList(
    BuildContext context,
    List<CategoryEntity> categories,
  ) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }
    return ReorderableListView.builder(
      onReorder: (oldIndex, newIndex) {
        final isIncome = categories.isNotEmpty && categories.first.isIncome;
        context.read<CategoryCubit>().reorderCategory(oldIndex, newIndex, isIncome);
      },
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return ListTile(
          key: ValueKey(cat.id),
          leading: CircleAvatar(
            backgroundColor: Color(cat.color),
            child: Text(cat.icon, style: const TextStyle(fontSize: 24)),
          ),
          title: Text(cat.name),
          subtitle: Text('${cat.subCategories.length} subcategories'),
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

  void _showAddCategoryDialog(
    BuildContext context, {
    CategoryEntity? category,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveCategorySheet(category: category),
    );
  }
}
