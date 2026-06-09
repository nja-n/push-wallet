import 'package:equatable/equatable.dart';

class WorkoutEntity extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final int durationMinutes;
  final List<String> exercises;
  final String notes;
  final bool isDeleted;

  const WorkoutEntity({
    required this.id,
    required this.title,
    required this.date,
    required this.durationMinutes,
    this.exercises = const [],
    this.notes = '',
    this.isDeleted = false,
  });

  WorkoutEntity copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? durationMinutes,
    List<String>? exercises,
    String? notes,
    bool? isDeleted,
  }) {
    return WorkoutEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        date,
        durationMinutes,
        exercises,
        notes,
        isDeleted,
      ];
}
