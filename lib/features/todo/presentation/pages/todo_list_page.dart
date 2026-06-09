import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/todo_entity.dart';
import '../bloc/todo_cubit.dart';
import '../widgets/add_todo_sheet.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  String _filter = 'All'; // 'All', 'Active', 'Completed'

  @override
  void initState() {
    super.initState();
    context.read<TodoCubit>().loadTodos();
  }

  void _showAddTodoSheet(BuildContext context, {TodoEntity? todo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTodoSheet(todo: todo),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TodoCubit>().loadTodos(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Active', 'Completed'].map((filterType) {
                final isSelected = _filter == filterType;
                return ChoiceChip(
                  label: Text(
                    filterType,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: Colors.grey[200],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = filterType);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          // Tasks List
          Expanded(
            child: BlocBuilder<TodoCubit, TodoState>(
              builder: (context, state) {
                if (state is TodoLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TodoError) {
                  return Center(child: Text(state.message));
                } else if (state is TodoLoaded) {
                  var list = state.todos;

                  // Filter list
                  if (_filter == 'Active') {
                    list = list.where((t) => !t.isCompleted).toList();
                  } else if (_filter == 'Completed') {
                    list = list.where((t) => t.isCompleted).toList();
                  }

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filter == 'Completed'
                                ? 'No completed tasks yet!'
                                : (_filter == 'Active'
                                    ? 'All caught up!'
                                    : 'No tasks. Add one above!'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final todo = list[index];
                      final isOverdue = todo.dueDate != null &&
                          todo.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
                          !todo.isCompleted;

                      return Card(
                        key: ValueKey(todo.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.grey.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showAddTodoSheet(context, todo: todo),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Completion Checkbox
                                GestureDetector(
                                  onTap: () => context
                                      .read<TodoCubit>()
                                      .toggleTodoCompletion(todo.id),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: todo.isCompleted
                                          ? primaryColor
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: todo.isCompleted
                                            ? primaryColor
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: todo.isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Task details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        todo.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: todo.isCompleted
                                              ? Colors.grey
                                              : Colors.black87,
                                          decoration: todo.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      if (todo.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          todo.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            decoration: todo.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          // Priority Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _priorityColor(todo.priority)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              todo.priority,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _priorityColor(todo.priority)
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ),
                                          if (todo.dueDate != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: isOverdue
                                                  ? Colors.red
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('MMM d').format(todo.dueDate!),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isOverdue
                                                    ? Colors.red
                                                    : Colors.grey[600],
                                                fontWeight: isOverdue
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    context.read<TodoCubit>().removeTodo(todo.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
