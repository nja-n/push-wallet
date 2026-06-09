import 'package:hive/hive.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../domain/entities/workout_entity.dart';
import '../domain/usecases/workout_usecases.dart';

part 'workout_data.g.dart';

@HiveType(typeId: 5)
class WorkoutModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final int durationMinutes;
  @HiveField(4)
  final List<String> exercises;
  @HiveField(5)
  final String notes;
  @HiveField(6)
  final bool isDeleted;

  WorkoutModel({
    required this.id,
    required this.title,
    required this.date,
    required this.durationMinutes,
    required this.exercises,
    required this.notes,
    required this.isDeleted,
  });

  factory WorkoutModel.fromEntity(WorkoutEntity entity) {
    return WorkoutModel(
      id: entity.id,
      title: entity.title,
      date: entity.date,
      durationMinutes: entity.durationMinutes,
      exercises: entity.exercises,
      notes: entity.notes,
      isDeleted: entity.isDeleted,
    );
  }

  WorkoutEntity toEntity() {
    return WorkoutEntity(
      id: id,
      title: title,
      date: date,
      durationMinutes: durationMinutes,
      exercises: exercises,
      notes: notes,
      isDeleted: isDeleted,
    );
  }
}

abstract class WorkoutLocalDataSource {
  Future<List<WorkoutModel>> getWorkouts();
  Future<void> cacheWorkout(WorkoutModel workout);
  Future<void> updateWorkout(WorkoutModel workout);
  Future<void> deleteWorkout(String id);
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final Box<WorkoutModel> workoutBox;
  WorkoutLocalDataSourceImpl(this.workoutBox);

  @override
  Future<List<WorkoutModel>> getWorkouts() async => workoutBox.values.toList();

  @override
  Future<void> cacheWorkout(WorkoutModel workout) async =>
      await workoutBox.put(workout.id, workout);

  @override
  Future<void> updateWorkout(WorkoutModel workout) async =>
      await workoutBox.put(workout.id, workout);

  @override
  Future<void> deleteWorkout(String id) async => await workoutBox.delete(id);
}

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutLocalDataSource localDataSource;
  WorkoutRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<WorkoutEntity>>> getWorkouts() async {
    try {
      final models = await localDataSource.getWorkouts();
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addWorkout(WorkoutEntity workout) async {
    try {
      await localDataSource.cacheWorkout(WorkoutModel.fromEntity(workout));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateWorkout(WorkoutEntity workout) async {
    try {
      await localDataSource.updateWorkout(WorkoutModel.fromEntity(workout));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorkout(String id) async {
    try {
      await localDataSource.deleteWorkout(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
