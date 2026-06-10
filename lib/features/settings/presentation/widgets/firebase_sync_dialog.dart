import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/settings_cubit.dart';
import '../../../account/presentation/bloc/account_cubit.dart';
import '../../../category/presentation/bloc/category_cubit.dart';
import '../../../transaction/presentation/bloc/transaction_cubit.dart';
import '../../../todo/presentation/bloc/todo_cubit.dart';
import '../../../workout/presentation/bloc/workout_cubit.dart';

class FirebaseSyncDialog extends StatefulWidget {
  final bool isBackupMode; // true = backup, false = restore
  const FirebaseSyncDialog({super.key, required this.isBackupMode});

  @override
  State<FirebaseSyncDialog> createState() => _FirebaseSyncDialogState();
}

class _FirebaseSyncDialogState extends State<FirebaseSyncDialog> {
  late Box _settingsBox;
  bool _isLoadingBox = true;
  bool _isSyncing = false;
  String _syncStep = '';
  double _syncProgress = 0.0;
  bool _syncSuccess = false;
  String? _lastBackupTime;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Restore mode variables
  List<MapEntry<String, dynamic>> _backupsList = [];
  bool _loadingBackupsList = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    _settingsBox = await Hive.openBox('settings');
    final localTime = _settingsBox.get('last_firebase_backup_time') as String?;
    
    if (!mounted) return;
    
    setState(() {
      _lastBackupTime = localTime;
      _isLoadingBox = false;
    });

    if (!widget.isBackupMode && _currentUser != null) {
      _fetchBackupsList();
    }
  }

  Future<void> _fetchBackupsList() async {
    final settingsCubit = context.read<SettingsCubit>();
    setState(() {
      _loadingBackupsList = true;
      _errorMessage = null;
    });
    try {
      final backups = await settingsCubit.backupService.getAllCloudBackups();
      if (!mounted) return;
      setState(() {
        if (backups != null && backups.isNotEmpty) {
          final sortedKeys = backups.keys.toList()..sort();
          _backupsList = sortedKeys.reversed.map((key) => MapEntry(key, backups[key])).toList();
        } else {
          _backupsList = [];
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load backups: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingBackupsList = false;
        });
      }
    }
  }

  Future<void> _runBackup() async {
    final cubit = context.read<SettingsCubit>();
    setState(() {
      _isSyncing = true;
      _syncSuccess = false;
      _syncProgress = 0.2;
      _syncStep = 'Preparing data...';
    });

    await Future.delayed(const Duration(milliseconds: 400));
    
    setState(() {
      _syncProgress = 0.5;
      _syncStep = 'Uploading backup to Cloud...';
    });

    final success = await cubit.backupToFirebase();

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isSyncing = false;
      _syncSuccess = success;
      _syncProgress = 1.0;
      _syncStep = success ? 'Data backed up successfully!' : 'Backup failed.';
      if (success) {
        _lastBackupTime = _settingsBox.get('last_firebase_backup_time') as String?;
      }
    });
  }

  Future<void> _runSpecificRestore(dynamic backupVal) async {
    final settingsCubit = context.read<SettingsCubit>();
    final accountCubit = context.read<AccountCubit>();
    final categoryCubit = context.read<CategoryCubit>();
    final transactionCubit = context.read<TransactionCubit>();
    final todoCubit = context.read<TodoCubit>();
    final workoutCubit = context.read<WorkoutCubit>();

    setState(() {
      _isSyncing = true;
      _syncSuccess = false;
      _syncProgress = 0.3;
      _syncStep = 'Restoring backup data...';
    });

    await Future.delayed(const Duration(milliseconds: 400));

    final success = await settingsCubit.backupService.restoreSpecificBackup(backupVal);

    await Future.delayed(const Duration(milliseconds: 600));

    if (success && mounted) {
      accountCubit.loadAccounts();
      categoryCubit.loadCategories();
      transactionCubit.loadTransactions();
      todoCubit.loadTodos();
      workoutCubit.loadWorkouts();
      settingsCubit.loadSettings();
    }

    setState(() {
      _isSyncing = false;
      _syncSuccess = success;
      _syncProgress = 1.0;
      _syncStep = success ? 'Data restored successfully!' : 'Restore failed.';
    });
  }

  Future<void> _runPruneBackups() async {
    final settingsCubit = context.read<SettingsCubit>();
    if (_currentUser == null) return;
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.3;
      _syncStep = 'Cleaning up old backups...';
    });

    await settingsCubit.backupService.pruneOldBackups(_currentUser.uid);
    await _fetchBackupsList();

    setState(() {
      _isSyncing = false;
      _syncSuccess = true;
      _syncProgress = 1.0;
      _syncStep = 'Old backups cleared (kept the 10 most recent).';
    });
  }

  Future<void> _deleteBackup(String key) async {
    if (_currentUser == null) return;
    final settingsCubit = context.read<SettingsCubit>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup from the cloud?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.5;
      _syncStep = 'Deleting backup...';
    });

    final success = await settingsCubit.backupService.deleteCloudBackup(_currentUser.uid, key);

    if (success && mounted) {
      await _fetchBackupsList();
    }

    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _syncProgress = 1.0;
      _syncStep = success ? 'Backup deleted successfully!' : 'Failed to delete backup.';
    });
  }

  String _getBackupDisplayDate(String key, dynamic val) {
    final settingsCubit = context.read<SettingsCubit>();
    final parsed = settingsCubit.backupService.parseBackupData(val);
    if (parsed != null && parsed.containsKey('timestamp')) {
      final ts = parsed['timestamp'] as String;
      return _formatDate(ts);
    }
    
    try {
      if (key.length >= 19) {
        final datePart = key.substring(0, 10);
        final timePart = key.substring(11).replaceAll('_', ':');
        final lastColonIdx = timePart.lastIndexOf(':');
        final cleanTime = lastColonIdx != -1 
            ? timePart.replaceRange(lastColonIdx, lastColonIdx + 1, '.')
            : timePart;
        final iso = '${datePart}T$cleanTime';
        return _formatDate(iso);
      }
    } catch (_) {}
    return key.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBox) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final titleText = widget.isBackupMode ? 'Backup to Cloud' : 'Restore from Cloud';
    final primaryColor = Theme.of(context).primaryColor;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            widget.isBackupMode ? Icons.cloud_upload : Icons.cloud_download,
            color: primaryColor,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            titleText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (_currentUser == null) ...[
              const Text(
                'You must be signed in to perform this action.',
                style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signed in as',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        Text(
                          _currentUser.email ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              if (_isSyncing) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: _syncProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _syncStep,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ] else if (_syncStep.isNotEmpty && _syncProgress == 1.0) ...[
                Column(
                  children: [
                    Icon(
                      _syncSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _syncSuccess ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _syncStep,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (!widget.isBackupMode)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _syncStep = '';
                            _syncProgress = 0.0;
                          });
                          _fetchBackupsList();
                        },
                        child: const Text('Back to Backups List'),
                      ),
                  ],
                ),
              ] else if (widget.isBackupMode) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _lastBackupTime != null
                          ? 'Last Cloud Backup: ${_formatDate(_lastBackupTime!)}'
                          : 'No backup found on Cloud',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _runBackup,
                      child: const Text('Sync Backup to Cloud'),
                    ),
                  ],
                ),
              ] else ...[
                // Restore list
                if (_loadingBackupsList)
                  const SizedBox(
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading backups list...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (_backupsList.isEmpty)
                  const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'No backups found on Cloud.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  const Text(
                    'Select a backup to restore:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _backupsList.length,
                      itemBuilder: (context, index) {
                        final item = _backupsList[index];
                        final backupService = context.read<SettingsCubit>().backupService;
                        final parsed = backupService.parseBackupData(item.value);
                        final bool hasAccounts = parsed?.containsKey('accounts') ?? false;
                        final bool hasCategories = parsed?.containsKey('categories') ?? false;
                        final bool hasTransactions = parsed?.containsKey('transactions') ?? false;
                        final bool hasSettings = parsed?.containsKey('settings') ?? false;
                        final bool hasTodos = parsed?.containsKey('todos') ?? false;
                        final bool hasWorkouts = parsed?.containsKey('workouts') ?? false;
                        final bool hasVersion = parsed?.containsKey('version') ?? false;
                        final bool hasTimestamp = parsed?.containsKey('timestamp') ?? false;
                        final bool isValid = parsed != null && (
                            hasVersion ||
                            hasTimestamp ||
                            hasAccounts ||
                            hasCategories ||
                            hasTransactions ||
                            hasSettings ||
                            hasTodos ||
                            hasWorkouts
                        );

                        debugPrint('Dialog - Key: ${item.key}, isValid: $isValid (accounts: $hasAccounts, categories: $hasCategories, transactions: $hasTransactions)');

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Icon(
                              isValid ? Icons.backup : Icons.error_outline,
                              color: isValid ? Colors.blue : Colors.red,
                            ),
                            title: Text(
                              _getBackupDisplayDate(item.key, item.value),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isValid ? 'Valid Format' : 'Invalid Backup Format',
                              style: TextStyle(
                                fontSize: 11,
                                color: isValid ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: isValid ? () => _runSpecificRestore(item.value) : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: const Size(60, 30),
                                  ),
                                  child: const Text('Restore', style: TextStyle(fontSize: 12)),
                                ),
                                if (index > 0) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteBackup(item.key),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Delete this backup',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_backupsList.length} backups',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (_backupsList.length > 10)
                        TextButton.icon(
                          onPressed: _runPruneBackups,
                          icon: const Icon(Icons.delete_sweep, size: 14, color: Colors.red),
                          label: const Text('Keep Last 10', style: TextStyle(fontSize: 11, color: Colors.red)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(60, 24),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
              
              // Shared Checkbox at the bottom for Auto-limit (if user is authenticated)
              if (!widget.isBackupMode && !_isSyncing) ...[
                const SizedBox(height: 8),
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    if (state is SettingsLoaded) {
                      return CheckboxListTile(
                        title: const Text(
                          'Auto-limit to 10 backups',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Deletes oldest backups when new ones are synced',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.zero,
                        value: state.autoLimitBackups,
                        onChanged: (val) {
                          if (val != null) {
                            context.read<SettingsCubit>().toggleAutoLimitBackups(val);
                          }
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_isSyncing ? 'Close' : 'Cancel'),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
