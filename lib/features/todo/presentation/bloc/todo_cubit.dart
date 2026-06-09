import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/usecases/todo_usecases.dart';
import '../../../../core/usecases/usecase.dart';

part 'todo_state.dart';

class TodoCubit extends Cubit<TodoState> {
  final GetTodos getTodos;
  final AddTodo addTodo;
  final UpdateTodo updateTodo;
  final DeleteTodo deleteTodo;

  TodoCubit({
    required this.getTodos,
    required this.addTodo,
    required this.updateTodo,
    required this.deleteTodo,
  }) : super(TodoInitial());

  Future<void> loadTodos() async {
    emit(TodoLoading());
    final result = await getTodos(NoParams());
    result.fold(
      (failure) => emit(const TodoError('Failed to load tasks')),
      (todos) {
        final activeTodos = todos.where((t) => !t.isDeleted).toList();
        // Sort active tasks: uncompleted first, then by priority, then by due date
        activeTodos.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          // Priority ranking
          final priorityA = _priorityValue(a.priority);
          final priorityB = _priorityValue(b.priority);
          if (priorityA != priorityB) {
            return priorityB.compareTo(priorityA); // High priority first
          }
          if (a.dueDate != null && b.dueDate != null) {
            return a.dueDate!.compareTo(b.dueDate!);
          }
          if (a.dueDate != null) return -1;
          if (b.dueDate != null) return 1;
          return a.title.compareTo(b.title);
        });
        emit(TodoLoaded(activeTodos));
      },
    );
  }

  int _priorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> createTodo(TodoEntity todo) async {
    emit(TodoLoading());
    final result = await addTodo(todo);
    result.fold(
      (failure) => emit(const TodoError('Failed to add task')),
      (_) => loadTodos(),
    );
  }

  Future<void> toggleTodoCompletion(String id) async {
    final currentState = state;
    if (currentState is TodoLoaded) {
      try {
        final todo = currentState.todos.firstWhere((t) => t.id == id);
        emit(TodoLoading());
        final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
        final result = await updateTodo(updatedTodo);
        result.fold(
          (failure) => emit(const TodoError('Failed to update task')),
          (_) => loadTodos(),
        );
      } catch (e) {
        emit(const TodoError('Task not found'));
      }
    }
  }

  Future<void> editTodo(TodoEntity todo) async {
    emit(TodoLoading());
    final result = await updateTodo(todo);
    result.fold(
      (failure) => emit(const TodoError('Failed to update task')),
      (_) => loadTodos(),
    );
  }

  Future<void> removeTodo(String id) async {
    final currentState = state;
    if (currentState is TodoLoaded) {
      try {
        final todo = currentState.todos.firstWhere((t) => t.id == id);
        emit(TodoLoading());
        final softDeletedTodo = todo.copyWith(isDeleted: true);
        final result = await updateTodo(softDeletedTodo);
        result.fold(
          (failure) => emit(const TodoError('Failed to delete task')),
          (_) => loadTodos(),
        );
      } catch (e) {
        emit(const TodoError('Task not found'));
      }
    }
  }
}
