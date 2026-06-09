import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/usecases/workout_usecases.dart';
import '../../../../core/usecases/usecase.dart';

part 'workout_state.dart';

class WorkoutCubit extends Cubit<WorkoutState> {
  final GetWorkouts getWorkouts;
  final AddWorkout addWorkout;
  final UpdateWorkout updateWorkout;
  final DeleteWorkout deleteWorkout;

  WorkoutCubit({
    required this.getWorkouts,
    required this.addWorkout,
    required this.updateWorkout,
    required this.deleteWorkout,
  }) : super(WorkoutInitial());

  Future<void> loadWorkouts() async {
    emit(WorkoutLoading());
    final result = await getWorkouts(NoParams());
    result.fold(
      (failure) => emit(const WorkoutError('Failed to load workouts')),
      (workouts) {
        final activeWorkouts = workouts.where((w) => !w.isDeleted).toList();
        // Sort workouts: newest first
        activeWorkouts.sort((a, b) => b.date.compareTo(a.date));
        emit(WorkoutLoaded(activeWorkouts));
      },
    );
  }

  Future<void> createWorkout(WorkoutEntity workout) async {
    emit(WorkoutLoading());
    final result = await addWorkout(workout);
    result.fold(
      (failure) => emit(const WorkoutError('Failed to log workout')),
      (_) => loadWorkouts(),
    );
  }

  Future<void> editWorkout(WorkoutEntity workout) async {
    emit(WorkoutLoading());
    final result = await updateWorkout(workout);
    result.fold(
      (failure) => emit(const WorkoutError('Failed to update workout')),
      (_) => loadWorkouts(),
    );
  }

  Future<void> removeWorkout(String id) async {
    final currentState = state;
    if (currentState is WorkoutLoaded) {
      try {
        final workout = currentState.workouts.firstWhere((w) => w.id == id);
        emit(WorkoutLoading());
        final softDeletedWorkout = workout.copyWith(isDeleted: true);
        final result = await updateWorkout(softDeletedWorkout);
        result.fold(
          (failure) => emit(const WorkoutError('Failed to delete workout')),
          (_) => loadWorkouts(),
        );
      } catch (e) {
        emit(const WorkoutError('Workout not found'));
      }
    }
  }
}
