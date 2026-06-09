import 'package:hive/hive.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../domain/entities/todo_entity.dart';
import '../domain/usecases/todo_usecases.dart';

part 'todo_data.g.dart';

@HiveType(typeId: 4)
class TodoModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final bool isCompleted;
  @HiveField(4)
  final DateTime? dueDate;
  @HiveField(5)
  final String priority;
  @HiveField(6)
  final bool isDeleted;

  TodoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.dueDate,
    required this.priority,
    required this.isDeleted,
  });

  factory TodoModel.fromEntity(TodoEntity entity) {
    return TodoModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      isCompleted: entity.isCompleted,
      dueDate: entity.dueDate,
      priority: entity.priority,
      isDeleted: entity.isDeleted,
    );
  }

  TodoEntity toEntity() {
    return TodoEntity(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      dueDate: dueDate,
      priority: priority,
      isDeleted: isDeleted,
    );
  }
}

abstract class TodoLocalDataSource {
  Future<List<TodoModel>> getTodos();
  Future<void> cacheTodo(TodoModel todo);
  Future<void> updateTodo(TodoModel todo);
  Future<void> deleteTodo(String id);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  final Box<TodoModel> todoBox;
  TodoLocalDataSourceImpl(this.todoBox);

  @override
  Future<List<TodoModel>> getTodos() async => todoBox.values.toList();

  @override
  Future<void> cacheTodo(TodoModel todo) async =>
      await todoBox.put(todo.id, todo);

  @override
  Future<void> updateTodo(TodoModel todo) async =>
      await todoBox.put(todo.id, todo);

  @override
  Future<void> deleteTodo(String id) async => await todoBox.delete(id);
}

class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource localDataSource;
  TodoRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<TodoEntity>>> getTodos() async {
    try {
      final models = await localDataSource.getTodos();
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addTodo(TodoEntity todo) async {
    try {
      await localDataSource.cacheTodo(TodoModel.fromEntity(todo));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTodo(TodoEntity todo) async {
    try {
      await localDataSource.updateTodo(TodoModel.fromEntity(todo));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTodo(String id) async {
    try {
      await localDataSource.deleteTodo(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
