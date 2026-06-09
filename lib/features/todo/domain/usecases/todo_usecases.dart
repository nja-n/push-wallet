import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/todo_entity.dart';

abstract class TodoRepository {
  Future<Either<Failure, List<TodoEntity>>> getTodos();
  Future<Either<Failure, void>> addTodo(TodoEntity todo);
  Future<Either<Failure, void>> updateTodo(TodoEntity todo);
  Future<Either<Failure, void>> deleteTodo(String id);
}

class GetTodos implements UseCase<List<TodoEntity>, NoParams> {
  final TodoRepository repository;
  GetTodos(this.repository);

  @override
  Future<Either<Failure, List<TodoEntity>>> call(NoParams params) =>
      repository.getTodos();
}

class AddTodo implements UseCase<void, TodoEntity> {
  final TodoRepository repository;
  AddTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(TodoEntity todo) =>
      repository.addTodo(todo);
}

class UpdateTodo implements UseCase<void, TodoEntity> {
  final TodoRepository repository;
  UpdateTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(TodoEntity todo) =>
      repository.updateTodo(todo);
}

class DeleteTodo implements UseCase<void, String> {
  final TodoRepository repository;
  DeleteTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) =>
      repository.deleteTodo(id);
}
