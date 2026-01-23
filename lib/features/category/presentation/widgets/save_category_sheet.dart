import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/category/domain/entities/category.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';
import 'package:uuid/uuid.dart';

import 'package:push_wallet/features/category/domain/entities/sub_category.dart';

class SaveCategorySheet extends StatefulWidget {
  final Category? category;
  const SaveCategorySheet({super.key, this.category});

  @override
  State<SaveCategorySheet> createState() => _SaveCategorySheetState();
}

class _SaveCategorySheetState extends State<SaveCategorySheet> {
  final _nameController = TextEditingController();
  final _subCategoryController = TextEditingController();
  List<SubCategory> _subCategories = [];
  bool _isIncome = false;
  int _selectedColor = 0xFF4CAF50;
  String _selectedIcon = '📁';

  final List<int> _colors = [
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFF2196F3, // Blue
    0xFFFFC107, // Amber
    0xFFFF5722, // Deep Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];

  final List<String> _icons = [
    '📁',
    '🍔',
    '🛒',
    '🎮',
    '🚗',
    '🏠',
    '✈️',
    '💡',
    '🏥',
    '🎓',
    '🎁',
    '💼',
    '💵',
    '💰',
    '🏋️',
    '🎬',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _isIncome = widget.category!.isIncome;
      _selectedColor = widget.category!.color;
      _selectedIcon = widget.category!.icon;
      _subCategories = List.from(widget.category!.subCategories);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Category' : 'New Category',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Icon Picker
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(_selectedColor).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(_selectedColor), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedIcon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon
                            ? Colors.grey.shade200
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Color Picker
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      backgroundColor: Color(color),
                      radius: 20,
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Is Income?'),
              value: _isIncome,
              onChanged: (val) => setState(() => _isIncome = val),
            ),

            const SizedBox(height: 12),
            Text(
              'Subcategories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Add Subcategory',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_subCategoryController.text.isNotEmpty) {
                      setState(() {
                        _subCategories.add(
                          SubCategory(
                            id: const Uuid().v4(),
                            name: _subCategoryController.text,
                          ),
                        );
                        _subCategoryController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_subCategories.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subCategories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sub = _subCategories[index];
                    return ListTile(
                      title: Text(sub.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          setState(() {
                            _subCategories.removeAt(index);
                          });
                        },
                      ),
                      dense: true,
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;

                final cubit = context.read<CategoryCubit>();
                final state = cubit.state;

                if (state is CategoryLoaded) {
                  final duplicate = state.categories.any((c) {
                    if (isEdit && c.id == widget.category!.id) return false;
                    return c.name.toLowerCase() == name.toLowerCase() &&
                        c.isIncome == _isIncome &&
                        !c.isDeleted;
                  });

                  if (duplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Category "$name" already exists in ${_isIncome ? 'Income' : 'Expense'}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                if (isEdit) {
                  final updated = Category(
                    id: widget.category!.id,
                    name: name,
                    isIncome: _isIncome,
                    color: _selectedColor,
                    icon: _selectedIcon,
                    subCategories: _subCategories,
                    isDeleted: widget.category!.isDeleted,
                  );
                  cubit.editCategory(updated);
                } else {
                  final newCategory = Category(
                    id: const Uuid().v4(),
                    name: name,
                    isIncome: _isIncome,
                    color: _selectedColor,
                    icon: _selectedIcon,
                    subCategories: _subCategories,
                  );
                  cubit.createCategory(newCategory);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Save Changes' : 'Create Category'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
