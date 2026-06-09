import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/workout_entity.dart';
import '../bloc/workout_cubit.dart';

class AddWorkoutSheet extends StatefulWidget {
  final WorkoutEntity? workout;
  const AddWorkoutSheet({super.key, this.workout});

  @override
  State<AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<AddWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _notesController;
  late TextEditingController _exerciseController;
  late DateTime _date;
  late List<String> _exercises;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.workout?.title ?? '');
    _durationController = TextEditingController(
        text: widget.workout?.durationMinutes.toString() ?? '30');
    _notesController = TextEditingController(text: widget.workout?.notes ?? '');
    _exerciseController = TextEditingController();
    _date = widget.workout?.date ?? DateTime.now();
    _exercises = List<String>.from(widget.workout?.exercises ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _addExercise() {
    final text = _exerciseController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _exercises.add(text);
        _exerciseController.clear();
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.workout != null;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Workout Log' : 'Log Workout Session',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Workout Name',
                          hintText: 'e.g., Upper Body Strength',
                          prefixIcon: Icon(Icons.fitness_center_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a workout name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (mins)',
                                prefixIcon: Icon(Icons.timer_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || int.tryParse(val) == null) {
                                  return 'Enter minutes';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                          .inputDecorationTheme
                                          .fillColor ??
                                      Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        color: primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMM d, yyyy').format(_date),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Exercises Done',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _exerciseController,
                              decoration: const InputDecoration(
                                labelText: 'Add Exercise',
                                hintText: 'e.g., Push-ups: 3 sets of 15',
                              ),
                              onFieldSubmitted: (_) => _addExercise(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addExercise,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // List of exercises
                      if (_exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No exercises added yet.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              color: Colors.grey[100],
                              elevation: 0,
                              child: ListTile(
                                dense: true,
                                title: Text(_exercises[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => _removeExercise(index),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Workout Notes (Optional)',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final cubit = context.read<WorkoutCubit>();
                    final duration = int.parse(_durationController.text);
                    if (isEdit) {
                      final updated = widget.workout!.copyWith(
                        title: _titleController.text.trim(),
                        durationMinutes: duration,
                        date: _date,
                        exercises: _exercises,
                        notes: _notesController.text.trim(),
                      );
                      cubit.editWorkout(updated);
                    } else {
                      final workout = WorkoutEntity(
                        id: const Uuid().v4(),
                        title: _titleController.text.trim(),
                        durationMinutes: duration,
                        date: _date,
                        exercises: _exercises,
                        notes: _notesController.text.trim(),
                      );
                      cubit.createWorkout(workout);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Log Session'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
