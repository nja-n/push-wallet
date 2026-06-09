import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/workout_entity.dart';

abstract class WorkoutRepository {
  Future<Either<Failure, List<WorkoutEntity>>> getWorkouts();
  Future<Either<Failure, void>> addWorkout(WorkoutEntity workout);
  Future<Either<Failure, void>> updateWorkout(WorkoutEntity workout);
  Future<Either<Failure, void>> deleteWorkout(String id);
}

class GetWorkouts implements UseCase<List<WorkoutEntity>, NoParams> {
  final WorkoutRepository repository;
  GetWorkouts(this.repository);

  @override
  Future<Either<Failure, List<WorkoutEntity>>> call(NoParams params) =>
      repository.getWorkouts();
}

class AddWorkout implements UseCase<void, WorkoutEntity> {
  final WorkoutRepository repository;
  AddWorkout(this.repository);

  @override
  Future<Either<Failure, void>> call(WorkoutEntity workout) =>
      repository.addWorkout(workout);
}

class UpdateWorkout implements UseCase<void, WorkoutEntity> {
  final WorkoutRepository repository;
  UpdateWorkout(this.repository);

  @override
  Future<Either<Failure, void>> call(WorkoutEntity workout) =>
      repository.updateWorkout(workout);
}

class DeleteWorkout implements UseCase<void, String> {
  final WorkoutRepository repository;
  DeleteWorkout(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) =>
      repository.deleteWorkout(id);
}
