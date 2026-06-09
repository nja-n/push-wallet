import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/workout_entity.dart';
import '../bloc/workout_cubit.dart';
import '../widgets/add_workout_sheet.dart';

class WorkoutListPage extends StatefulWidget {
  const WorkoutListPage({super.key});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends State<WorkoutListPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkoutCubit>().loadWorkouts();
  }

  void _showAddWorkoutSheet(BuildContext context, {WorkoutEntity? workout}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddWorkoutSheet(workout: workout),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<WorkoutCubit>().loadWorkouts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkoutSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<WorkoutCubit, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WorkoutError) {
            return Center(child: Text(state.message));
          } else if (state is WorkoutLoaded) {
            final workouts = state.workouts;

            // Stats calculation
            final totalSessions = workouts.length;
            final totalMinutes = workouts.fold(0, (sum, w) => sum + w.durationMinutes);
            final avgDuration = totalSessions == 0 ? 0 : (totalMinutes / totalSessions).round();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Premium Stats Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade800, Colors.orange.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Sessions', totalSessions.toString(), Icons.fitness_center),
                      _buildVerticalDivider(),
                      _buildStatItem('Total Time', '$totalMinutes m', Icons.timer),
                      _buildVerticalDivider(),
                      _buildStatItem('Avg Session', '$avgDuration m', Icons.bar_chart),
                    ],
                  ),
                ),
                // Log title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'History Log',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                // Workouts History List
                Expanded(
                  child: workouts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No workouts logged yet. Let\'s get active!',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: workouts.length,
                          itemBuilder: (context, index) {
                            final workout = workouts[index];
                            return _WorkoutCard(
                              workout: workout,
                              onEdit: () => _showAddWorkoutSheet(context, workout: workout),
                              onDelete: () => context.read<WorkoutCubit>().removeWorkout(workout.id),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  final WorkoutEntity workout;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutCard({
    required this.workout,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, MMM d').format(widget.workout.date);
    final year = DateFormat('yyyy').format(widget.workout.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.run_circle_outlined, color: Colors.orange),
            ),
            title: Text(
              widget.workout.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$formattedDate, $year • ${widget.workout.durationMinutes} mins'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  onPressed: widget.onDelete,
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.workout.exercises.isNotEmpty) ...[
                    const Text(
                      'Exercises Completed:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...widget.workout.exercises.map((exercise) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(exercise)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  if (widget.workout.notes.isNotEmpty) ...[
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.workout.notes,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (widget.workout.exercises.isEmpty && widget.workout.notes.isEmpty)
                    const Text(
                      'No exercises or notes recorded.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
